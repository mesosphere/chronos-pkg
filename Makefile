# Note that the prefix affects the init scripts as well.
prefix := usr/local

.PHONY: rpm
rpm: version with-upstart
	cd toor && \
	fpm -t rpm -s dir \
		-n chronos -v `cat ../version` -p ../chronos.rpm .

.PHONY: fedora
fedora: version with-serviced
	cd toor && \
	fpm -t rpm -s dir \
		-n marathon -v `cat ../version` -p ../marathon.rpm .

.PHONY: deb
deb: version with-upstart
	cd toor && \
	fpm -t deb -s dir \
		-n chronos -v `cat ../version` -p ../chronos.deb .

.PHONY: osx
osx: version just-jar
	cd toor && \
	fpm -t osxpkg --osxpkg-identifier-prefix io.mesosphere -s dir \
		-n chronos -v `cat ../version` -p ../chronos.pkg .

.PHONY: with-upstart
with-upstart: just-jar chronos.conf
	mkdir -p toor/etc/init
	cp chronos.conf toor/etc/init/

.PHONY: with-serviced
with-serviced: just-jar marathon.service
	mkdir -p toor/usr/lib/systemd/system/
	cp marathon.service toor/usr/lib/systemd/system/

.PHONY: just-jar
just-jar: chronos-runnable.jar
	mkdir -p toor/$(prefix)/bin
	cp chronos-runnable.jar toor/$(prefix)/bin/chronos
	chmod 755 toor/$(prefix)/bin/chronos

version: plugin := org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate
version: chronos-runnable.jar
	( cd chronos && \
		mvn $(plugin) -Dexpression=project.version | sed '/^\[/d' ) | \
		tail -n1 | sed 's/_/-/' > version

chronos-runnable.jar:
	cd chronos && mvn package && cd .. && bin/build-distribution

