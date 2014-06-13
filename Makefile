# Note that the prefix affects the init scripts as well.
PREFIX := usr/local

# Command to extract from X.X.X-rcX the version (X.X.X)
EXTRACT_VER := perl -n -e'/^([0-9]+\.[0-9]+\.[0-9]+).*/ && print $$1'

PKG_VER := $(shell cd chronos && \
	mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate \
	-Dexpression=project.version | sed '/^\[/d' | tail -n1 | sed 's/_/-/' | \
	$(EXTRACT_VER))

PKG_REL := 0.1.$(shell date -u +'%Y%m%d%H%M')

.PHONY: all
all: snapshot

.PHONY: release
release: PKG_REL := 1
release: deb rpm

.PHONY: snapshot
snapshot: deb rpm

.PHONY: rpm
rpm: with-upstart
	fpm -t rpm -s dir \
		-n chronos -v $(PKG_VER) --iteration $(PKG_REL) -C toor .

.PHONY: fedora
fedora: with-serviced
	fpm -t rpm -s dir \
		-n chronos -v $(PKG_VER) --iteration $(PKG_REL) -C toor .

.PHONY: deb
deb: with-upstart
	fpm -t deb -s dir \
		-n chronos -v $(PKG_VER) --iteration $(PKG_REL) -C toor .

.PHONY: osx
osx: just-jar
	fpm -t osxpkg --osxpkg-identifier-prefix io.mesosphere -s dir \
		-n chronos -v $(PKG_VER) --iteration $(PKG_REL) -C toor .

.PHONY: with-upstart
with-upstart: just-jar chronos.conf
	mkdir -p toor/etc/init
	cp chronos.conf toor/etc/init/

.PHONY: with-serviced
with-serviced: just-jar chronos.service
	mkdir -p toor/usr/lib/systemd/system/
	cp chronos.service toor/usr/lib/systemd/system/

.PHONY: just-jar
just-jar: chronos-runnable.jar
	mkdir -p toor/$(PREFIX)/bin
	cp chronos-runnable.jar toor/$(PREFIX)/bin/chronos
	chmod 755 toor/$(PREFIX)/bin/chronos

# Tests should really not be skipped... unfortunately, they appear to fail
# regularly and non-deterministically.
chronos-runnable.jar:
	cd chronos && mvn -DskipTests=true package
	bin/build-distribution

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

