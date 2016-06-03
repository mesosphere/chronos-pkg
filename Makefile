# Note that the prefix affects the init scripts as well.
PREFIX := usr

# Command to extract from X.X.X-rcX the version (X.X.X)
EXTRACT_VER := perl -n -e'/^([0-9]+\.[0-9]+\.[0-9]+).*/ && print $$1'

PKG_VER := $(shell cd chronos && \
	mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate \
	-Dexpression=project.version | sed '/^\[/d' | tail -n1 | sed 's/_/-/' | \
	$(EXTRACT_VER))

PKG_REL := 0.1.$(shell date -u +'%Y%m%d%H%M%S')

FPM_OPTS := -s dir -n chronos -v $(PKG_VER) \
	--architecture native \
	--url "https://github.com/mesos/chronos" \
	--license Apache-2.0 \
	--description "Fault tolerant job scheduler for Mesos which handles\
		dependencies and ISO8601 based schedules" \
	--maintainer "Mesosphere Package Builder <support@mesosphere.io>" \
	--vendor "Mesosphere, Inc."
FPM_OPTS_DEB := -t deb --config-files etc/ \
	-d 'java8-runtime-headless | java7-runtime-headless | java6-runtime-headless' \
	-d 'lsb-release' \
	--after-install chronos.postinst \
	--after-remove chronos.postrm
FPM_OPTS_DEB_INIT := --deb-init chronos.init
FPM_OPTS_RPM := -t rpm --config-files etc/ \
	-d coreutils -d 'java >= 1.6'
FPM_OPTS_OSX := -t osxpkg --osxpkg-identifier-prefix io.mesosphere

.PHONY: help
help:
	@echo "Please choose one of the following targets:"
	@echo "  all, deb, rpm, fedora, osx, centos7"
	@echo "For release builds:"
	@echo "  make PKG_REL=1 deb"
	@echo "To override package release version:"
	@echo "  make PKG_REL=0.2.20141228050159 rpm"
	@exit 0

.PHONY: all
all: deb rpm

.PHONY: deb
deb: ubuntu debian

.PHONY: rpm
rpm: el

.PHONY: el
el: el6 el7

.PHONY: fedora
fedora: fedora20 fedora21 fedora22

.PHONY: ubuntu
ubuntu: ubuntu-precise ubuntu-trusty ubuntu-vivid

.PHONY: debian
debian: debian-jessie

.PHONY: debian-jessie
debian-jessie: debian-jessie-81

.PHONY: fedora20
fedora20: toor/fedora20/usr/lib/systemd/system/chronos.service
fedora20: toor/fedora20/$(PREFIX)/bin/chronos
fedora20: toor/fedora20/etc/chronos/conf/http_port
	fpm -C toor/fedora20 --iteration $(PKG_REL).fc20 $(FPM_OPTS_RPM) $(FPM_OPTS) .

.PHONY: fedora21
fedora21: toor/fedora21/usr/lib/systemd/system/chronos.service
fedora21: toor/fedora21/$(PREFIX)/bin/chronos
fedora21: toor/fedora21/etc/chronos/conf/http_port
	fpm -C toor/fedora21 --iteration $(PKG_REL).fc21 $(FPM_OPTS_RPM) $(FPM_OPTS) .

.PHONY: fedora22
fedora22: toor/fedora22/usr/lib/systemd/system/chronos.service
fedora22: toor/fedora22/$(PREFIX)/bin/chronos
fedora22: toor/fedora22/etc/chronos/conf/http_port
	fpm -C toor/fedora22 --iteration $(PKG_REL).fc22 $(FPM_OPTS_RPM) $(FPM_OPTS) .

.PHONY: el6
el6: toor/el6/etc/init/chronos.conf
el6: toor/el6/$(PREFIX)/bin/chronos
el6: toor/el6/etc/chronos/conf/http_port
	fpm -C toor/el6 --iteration $(PKG_REL).el6 $(FPM_OPTS_RPM) $(FPM_OPTS) .

.PHONY: el7
el7: toor/el7/usr/lib/systemd/system/chronos.service
el7: toor/el7/$(PREFIX)/bin/chronos
el7: toor/el7/etc/chronos/conf/http_port
el7: chronos.systemd.postinst
	fpm -C toor/el7 --iteration $(PKG_REL).el7 \
		--after-install chronos.systemd.postinst \
		$(FPM_OPTS_RPM) $(FPM_OPTS) .

.PHONY: ubuntu-precise
ubuntu-precise: toor/ubuntu-precise/etc/init/chronos.conf
ubuntu-precise: toor/ubuntu-precise/etc/init.d/chronos
ubuntu-precise: toor/ubuntu-precise/$(PREFIX)/bin/chronos
ubuntu-precise: chronos.postinst
ubuntu-precise: chronos.postrm
ubuntu-precise: toor/ubuntu-precise/etc/chronos/conf/http_port
	fpm -C toor/ubuntu-precise --iteration $(PKG_REL).ubuntu1204 $(FPM_OPTS_DEB) $(FPM_OPTS_DEB_INIT) $(FPM_OPTS) .

.PHONY: ubuntu-quantal
ubuntu-quantal: toor/ubuntu-quantal/etc/init/chronos.conf
ubuntu-quantal: toor/ubuntu-quantal/etc/init.d/chronos
ubuntu-quantal: toor/ubuntu-quantal/$(PREFIX)/bin/chronos
ubuntu-quantal: chronos.postinst
ubuntu-quantal: chronos.postrm
ubuntu-quantal: toor/ubuntu-quantal/etc/chronos/conf/http_port
	fpm -C toor/ubuntu-quantal --iteration $(PKG_REL).ubuntu1210 $(FPM_OPTS_DEB) $(FPM_OPTS_DEB_INIT) $(FPM_OPTS) .

.PHONY: ubuntu-raring
ubuntu-raring: toor/ubuntu-raring/etc/init/chronos.conf
ubuntu-raring: toor/ubuntu-raring/etc/init.d/chronos
ubuntu-raring: toor/ubuntu-raring/$(PREFIX)/bin/chronos
ubuntu-raring: chronos.postinst
ubuntu-raring: chronos.postrm
ubuntu-raring: toor/ubuntu-raring/etc/chronos/conf/http_port
	fpm -C toor/ubuntu-raring --iteration $(PKG_REL).ubuntu1304 $(FPM_OPTS_DEB) $(FPM_OPTS_DEB_INIT) $(FPM_OPTS) .

.PHONY: ubuntu-saucy
ubuntu-saucy: toor/ubuntu-saucy/etc/init/chronos.conf
ubuntu-saucy: toor/ubuntu-saucy/etc/init.d/chronos
ubuntu-saucy: toor/ubuntu-saucy/$(PREFIX)/bin/chronos
ubuntu-saucy: chronos.postinst
ubuntu-saucy: chronos.postrm
ubuntu-saucy: toor/ubuntu-saucy/etc/chronos/conf/http_port
	fpm -C toor/ubuntu-saucy --iteration $(PKG_REL).ubuntu1310 $(FPM_OPTS_DEB) $(FPM_OPTS_DEB_INIT) $(FPM_OPTS) .

.PHONY: ubuntu-trusty
ubuntu-trusty: toor/ubuntu-trusty/etc/init/chronos.conf
ubuntu-trusty: toor/ubuntu-trusty/etc/init.d/chronos
ubuntu-trusty: toor/ubuntu-trusty/$(PREFIX)/bin/chronos
ubuntu-trusty: chronos.postinst
ubuntu-trusty: chronos.postrm
ubuntu-trusty: toor/ubuntu-trusty/etc/chronos/conf/http_port
	fpm -C toor/ubuntu-trusty --iteration $(PKG_REL).ubuntu1404 $(FPM_OPTS_DEB) $(FPM_OPTS_DEB_INIT) $(FPM_OPTS) .

.PHONY: ubuntu-utopic
ubuntu-utopic: toor/ubuntu-utopic/etc/init/chronos.conf
ubuntu-utopic: toor/ubuntu-utopic/etc/init.d/chronos
ubuntu-utopic: toor/ubuntu-utopic/$(PREFIX)/bin/chronos
ubuntu-utopic: chronos.postinst
ubuntu-utopic: chronos.postrm
ubuntu-utopic: toor/ubuntu-utopic/etc/chronos/conf/http_port
	fpm -C toor/ubuntu-utopic --iteration $(PKG_REL).ubuntu1410 $(FPM_OPTS_DEB) $(FPM_OPTS_DEB_INIT) $(FPM_OPTS) .

.PHONY: ubuntu-vivid
ubuntu-vivid: toor/ubuntu-vivid/lib/systemd/system/chronos.service
ubuntu-vivid: toor/ubuntu-vivid/$(PREFIX)/bin/chronos
ubuntu-vivid: toor/ubuntu-vivid/etc/chronos/conf/http_port
ubuntu-vivid: chronos.systemd.postinst
	fpm -C toor/ubuntu-vivid --iteration $(PKG_REL).ubuntu1504 \
		--after-install chronos.systemd.postinst \
		$(FPM_OPTS_DEB) $(FPM_OPTS) .

.PHONY: ubuntu-wily
ubuntu-wily: toor/ubuntu-wily/lib/systemd/system/chronos.service
ubuntu-wily: toor/ubuntu-wily/$(PREFIX)/bin/chronos
ubuntu-wily: toor/ubuntu-wily/etc/chronos/conf/http_port
ubuntu-wily: chronos.systemd.postinst
	fpm -C toor/ubuntu-wily --iteration $(PKG_REL).ubuntu1510 \
		--after-install chronos.systemd.postinst \
		$(FPM_OPTS_DEB) $(FPM_OPTS) .

.PHONY: ubuntu-xenial
ubuntu-xenial: toor/ubuntu-xenial/lib/systemd/system/chronos.service
ubuntu-xenial: toor/ubuntu-xenial/$(PREFIX)/bin/chronos
ubuntu-xenial: toor/ubuntu-xenial/etc/chronos/conf/http_port
ubuntu-xenial: chronos.systemd.postinst
	fpm -C toor/ubuntu-xenial --iteration $(PKG_REL).ubuntu1604 \
		--after-install chronos.systemd.postinst \
		$(FPM_OPTS_DEB) $(FPM_OPTS) .

.PHONY: debian-wheezy-77
debian-wheezy-77: toor/debian-wheezy-77/etc/init/chronos.conf
debian-wheezy-77: toor/debian-wheezy-77/etc/init.d/chronos
debian-wheezy-77: toor/debian-wheezy-77/$(PREFIX)/bin/chronos
debian-wheezy-77: chronos.postinst
debian-wheezy-77: chronos.postrm
debian-wheezy-77: toor/debian-wheezy-77/etc/chronos/conf/http_port
	fpm -C toor/debian-wheezy-77 --iteration $(PKG_REL).debian77 $(FPM_OPTS_DEB) $(FPM_OPTS_DEB_INIT) $(FPM_OPTS) .

.PHONY: debian-jessie-81
debian-jessie-81: toor/debian-jessie-81/lib/systemd/system/chronos.service
debian-jessie-81: toor/debian-jessie-81/$(PREFIX)/bin/chronos
debian-jessie-81: toor/debian-jessie-81/etc/chronos/conf/http_port
debian-jessie-81: chronos.systemd.postinst
	fpm -C toor/debian-jessie-81 --iteration $(PKG_REL).debian81 \
		--after-install chronos.systemd.postinst \
		$(FPM_OPTS_DEB) $(FPM_OPTS) .

.PHONY: osx
osx: toor/osx/$(PREFIX)/bin/chronos
	fpm -C toor/osx --iteration $(PKG_REL) $(FPM_OPTS_OSX) $(FPM_OPTS) .

toor/%/etc/init/chronos.conf: chronos.conf
	mkdir -p "$(dir $@)"
	cp chronos.conf "$@"

toor/%/etc/init.d/chronos: chronos.init
	mkdir -p "$(dir $@)"
	cp chronos.init "$@"

toor/%/usr/lib/systemd/system/chronos.service: chronos.service
	mkdir -p "$(dir $@)"
	cp chronos.service "$@"

toor/%/lib/systemd/system/chronos.service: chronos.service
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
	rm -rf chronos-runnable.jar chronos*.deb chronos*.rpm chronos*.pkg toor chronos/target

.PHONY: prep-ubuntu
prep-ubuntu:
	sudo apt-get -y install default-jdk ruby-dev rpm maven node git
	sudo gem install fpm
	curl -sSfL \
		http://www.gtlib.gatech.edu/pub/apache/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz \
		--output /var/tmp/maven.tgz
	sudo mkdir -p /usr/local/apache-maven
	cd /usr/local/apache-maven && sudo tar xzvf /var/tmp/maven.tgz
	sudo ln -sf /usr/local/apache-maven/*/bin/mvn /usr/local/bin/mvn

