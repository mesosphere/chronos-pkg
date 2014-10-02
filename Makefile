# Note that the prefix affects the init scripts as well.
PREFIX := usr/local

# Command to extract from X.X.X-rcX the version (X.X.X)
EXTRACT_VER := perl -n -e'/^([0-9]+\.[0-9]+\.[0-9]+).*/ && print $$1'

PKG_VER := $(shell cd chronos && \
	mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate \
	-Dexpression=project.version | sed '/^\[/d' | tail -n1 | sed 's/_/-/' | \
	$(EXTRACT_VER))

PKG_REL := 0.1.$(shell date -u +'%Y%m%d%H%M%S')

FPM_OPTS := -s dir -n chronos -v $(PKG_VER) --iteration $(PKG_REL) \
	--architecture native \
	--url "https://github.com/mesosphere/chronos" \
	--license Apache-2.0 \
	--description "Fault tolerant job scheduler for Mesos which handles\
		dependencies and ISO8601 based schedules" \
	--maintainer "Mesosphere Package Builder <support@mesosphere.io>" \
	--vendor "Mesosphere, Inc."
FPM_OPTS_DEB := -t deb --config-files etc/ \
	-d 'java7-runtime-headless | java6-runtime-headless' \
	--deb-init chronos.init \
	--after-install chronos.postinst \
	--after-remove chronos.postrm
FPM_OPTS_RPM := -t rpm --config-files etc/ \
	-d coreutils -d 'java >= 1.6'
FPM_OPTS_OSX := -t osxpkg --osxpkg-identifier-prefix io.mesosphere

.PHONY: all
all: deb rpm

.PHONY: help
help:
	@echo "Please choose one of the following targets: deb, rpm, fedora, osx"
	@echo "For release builds:"
	@echo "  make PKG_REL=1 deb"
	@echo "To override package release version:"
	@echo "  make PKG_REL=0.2.20141228050159 rpm"
	@exit 0

.PHONY: rpm
rpm: toor/rpm/etc/init/chronos.conf
rpm: toor/rpm/$(PREFIX)/bin/chronos
rpm: toor/rpm/etc/chronos/conf/http_port
	fpm -C toor/rpm $(FPM_OPTS_RPM) $(FPM_OPTS) .

.PHONY: fedora
fedora: toor/fedora/usr/lib/systemd/system/chronos.service
fedora: toor/fedora/$(PREFIX)/bin/chronos
fedora: toor/fedora/etc/chronos/conf/http_port
	fpm -C toor/fedora $(FPM_OPTS_RPM) $(FPM_OPTS) .

.PHONY: deb
deb: toor/deb/etc/init/chronos.conf
deb: toor/deb/etc/init.d/chronos
deb: toor/deb/$(PREFIX)/bin/chronos
deb: chronos.postinst
deb: chronos.postrm
deb: toor/deb/etc/chronos/conf/http_port
	fpm -C toor/deb $(FPM_OPTS_DEB) $(FPM_OPTS) .

.PHONY: osx
osx: toor/osx/$(PREFIX)/bin/chronos
	fpm -C toor/osx $(FPM_OPTS_OSX) $(FPM_OPTS) .

toor/%/etc/init/chronos.conf: chronos.conf
	mkdir -p "$(dir $@)"
	cp chronos.conf "$@"

toor/%/etc/init.d/chronos: chronos.init
	mkdir -p "$(dir $@)"
	cp chronos.init "$@"

toor/%/usr/lib/systemd/system/chronos.service: chronos.service
	mkdir -p "$(dir $@)"
	cp chronos.service "$@"

toor/%/bin/chronos: chronos-runnable.jar
	mkdir -p "$(dir $@)"
	cp chronos-runnable.jar "$@"
	chmod 755 "$@"

toor/%/etc/chronos/conf/http_port:
	mkdir -p "$(dir $@)"
	echo 4400 > "$@"

# Tests should really not be skipped... unfortunately, they appear to fail
# regularly and non-deterministically.
chronos-runnable.jar:
	cd chronos && mvn -DskipTests=true package
	bin/build-distribution

.PHONY: clean
clean:
	rm -rf chronos-runnable.jar chronos*.deb chronos*.rpm chronos*.pkg toor

.PHONY: prep-ubuntu
prep-ubuntu:
	sudo apt-get -y install default-jdk ruby-dev rpm maven node git
	sudo gem install fpm
	curl -sSfL \
		http://mirrors.gigenet.com/apache/maven/maven-3/3.2.1/binaries/apache-maven-3.2.1-bin.tar.gz \
		--output /var/tmp/maven.tgz
	sudo mkdir -p /usr/local/apache-maven
	cd /usr/local/apache-maven && sudo tar xzvf /var/tmp/maven.tgz
	sudo ln -sf /usr/local/apache-maven/*/bin/mvn /usr/local/bin/mvn

