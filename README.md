# php-fpm
php代码一次性加载多次性运行。

### 解决报502异常，即调用参数fpm_entry_func配置的函数时zend_catch会导致php-fpm工作进程终止问题
vendor/yiisoft/yii2/base/ErrorHandler.php:253 =>  Unsetting an unknown or read-only property

