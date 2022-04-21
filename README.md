# php-fpm
php代码一次性加载多次性运行，增加redefine函数并实现php-fpm的worker pool配置的php_entry_file和php_entry_func。

#### YII2.0 demo
* entry.php

#### 解决yii异常处理句柄不生效问题
* 在文件 vendor/yiisoft/yii2/base/ErrorHandler.php:261 后添加如下代码(即error_get_last()所在行的后面)
  * error_clear_last();

### 编译
```sh
git clone https://github.com/php/php-src.git php-src
cd php-src
git clone https://github.com/talent518/php-fpm.git sapi/fpm2
./buildconf -f
./sapi/fpm2/build.sh
```
