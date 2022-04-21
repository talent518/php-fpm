fpm2: $(SAPI_FPM2_PATH)

$(SAPI_FPM2_PATH): $(PHP_GLOBAL_OBJS) $(PHP_BINARY_OBJS) $(PHP_FASTCGI_OBJS) $(PHP_FPM2_OBJS)
	$(BUILD_FPM2)

install-fpm2: $(SAPI_FPM2_PATH)
	@echo "Installing PHP fpm2 binary:        $(INSTALL_ROOT)$(sbindir)/"
	@$(mkinstalldirs) $(INSTALL_ROOT)$(sbindir)
	@$(mkinstalldirs) $(INSTALL_ROOT)$(localstatedir)/log
	@$(mkinstalldirs) $(INSTALL_ROOT)$(localstatedir)/run
	@$(INSTALL) -m 0755 $(SAPI_FPM2_PATH) $(INSTALL_ROOT)$(sbindir)/$(program_prefix)php-fpm2$(program_suffix)$(EXEEXT)

	@if test -f "$(INSTALL_ROOT)$(sysconfdir)/php-fpm2.conf"; then \
		echo "Installing PHP fpm2 defconfig:     skipping"; \
	else \
		echo "Installing PHP fpm2 defconfig:     $(INSTALL_ROOT)$(sysconfdir)/" && \
		$(mkinstalldirs) $(INSTALL_ROOT)$(sysconfdir)/php-fpm2.d; \
		$(INSTALL_DATA) sapi/fpm2/php-fpm.conf $(INSTALL_ROOT)$(sysconfdir)/php-fpm2.conf.default; \
		$(INSTALL_DATA) sapi/fpm2/www.conf $(INSTALL_ROOT)$(sysconfdir)/php-fpm2.d/www.conf.default; \
	fi

	@echo "Installing PHP fpm2 man page:      $(INSTALL_ROOT)$(mandir)/man8/"
	@$(mkinstalldirs) $(INSTALL_ROOT)$(mandir)/man8
	@$(INSTALL_DATA) sapi/fpm2/php-fpm.8 $(INSTALL_ROOT)$(mandir)/man8/php-fpm2$(program_suffix).8

	@echo "Installing PHP fpm2 status page:   $(INSTALL_ROOT)$(datadir)/fpm2/"
	@$(mkinstalldirs) $(INSTALL_ROOT)$(datadir)/fpm2
	@$(INSTALL_DATA) sapi/fpm2/status.html $(INSTALL_ROOT)$(datadir)/fpm2/status.html

