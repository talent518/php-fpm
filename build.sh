#!/bin/bash -l

php=${2:-php}
ZTS=
if [ "x$1" = "xzts" ]; then
	ZTS="--enable-maintainer-zts --with-tsrm-pthreads"
	php=${2:-phpts}
else
	ZTS="--with-mm"
fi

EXTENSION_DIR=/opt/$php/lib/extensions ./configure CFLAGS=-O2 CXXFLAGS=-O2 --prefix=/opt/$php --with-config-file-path=/opt/$php/etc --with-config-file-scan-dir=/opt/$php/etc/php.d --enable-embed --enable-fpm --with-fpm-systemd --with-fpm-acl --enable-fpm2 --enable-fpm2-entry-debug --with-fpm2-systemd --with-fpm2-acl --enable-phpdbg --with-openssl --with-kerberos --with-system-ciphers --with-zlib --enable-bcmath --with-bz2 --enable-calendar --with-curl --enable-dba=shared --with-enchant --enable-exif --with-ffi --enable-ftp --enable-gd --with-external-gd --with-webp --with-jpeg --with-xpm --with-freetype --enable-gd-jis-conv --with-gettext --with-gmp --with-mhash --with-imap --with-kerberos --with-imap-ssl --enable-intl --with-ldap --with-ldap-sasl --enable-mbstring --with-mysqli --enable-pcntl --with-pdo-mysql --with-pspell --with-libedit --with-readline --enable-shmop --with-snmp --enable-soap --enable-sockets --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-tidy --with-expat --with-xsl --enable-zend-test=shared --with-zip --enable-mysqlnd $ZTS && make -j4 && make install
