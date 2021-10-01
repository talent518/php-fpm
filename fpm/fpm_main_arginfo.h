/* This is a generated file, edit the .stub.php file instead.
 * Stub hash: b4ac4c0f1d91c354293e21185a2e6d9f99cc9fcc */

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_fastcgi_finish_request, 0, 0, _IS_BOOL, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_apache_request_headers, 0, 0, IS_ARRAY, 0)
ZEND_END_ARG_INFO()

#define arginfo_getallheaders arginfo_apache_request_headers

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_MASK_EX(arginfo_fpm_get_status, 0, 0, MAY_BE_ARRAY|MAY_BE_FALSE)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_redefine, 0, 2, _IS_BOOL, 0)
	ZEND_ARG_TYPE_INFO(0, constant_name, IS_STRING, 0)
	ZEND_ARG_INFO(0, value)
	ZEND_ARG_TYPE_INFO_WITH_DEFAULT_VALUE(0, case_insensitive, _IS_BOOL, 0, "false")
ZEND_END_ARG_INFO()


ZEND_FUNCTION(fastcgi_finish_request);
ZEND_FUNCTION(apache_request_headers);
ZEND_FUNCTION(fpm_get_status);
ZEND_FUNCTION(redefine);


static const zend_function_entry ext_functions[] = {
	ZEND_FE(fastcgi_finish_request, arginfo_fastcgi_finish_request)
	ZEND_FE(apache_request_headers, arginfo_apache_request_headers)
	ZEND_FALIAS(getallheaders, apache_request_headers, arginfo_getallheaders)
	ZEND_FE(fpm_get_status, arginfo_fpm_get_status)
	ZEND_FE(redefine, arginfo_redefine)
	ZEND_FE_END
};
