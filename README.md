# php-fpm
php代码一次性加载多次性运行。

#### YII2.0 demo
* entry.php
* entry2.php

#### 解决yii异常处理句柄不生效问题
* 在文件 vendor/yiisoft/yii2/base/ErrorHandler.php:261 后添加如下代码(即error_get_last()所在行的后面)
  * error_clear_last();

