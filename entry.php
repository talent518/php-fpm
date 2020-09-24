<?php
// comment out the following two lines when deployed to production

defined('YII_ENV') or define('YII_ENV', get_cfg_var('env') ?: 'dev');
// YII_ENV === 'pre' and defined('YII_ENV_PROD', true);
// defined('YII_DEBUG') or define('YII_DEBUG', YII_ENV !== 'prod');
define('YII_DEBUG', false);
define('OFF_API_LOG', true);

require __DIR__ . '/../vendor/autoload.php';
require __DIR__ . '/../vendor/yiisoft/yii2/Yii.php';

function yii_application_run() {
	$config = require __DIR__ . '/../config/web.php';
	(new yii\web\Application($config))->run();
	rev_close(\Yii::$app);
	\Yii::$app = null;
}

function rev_close(object $obj) {
	if(method_exists($obj, 'getComponents')) {
		foreach($obj->getComponents(false) as $_obj) {
			is_object($_obj) and rev_close($_obj);
		}
	}
	method_exists($obj, 'close') and $obj->close();
}
