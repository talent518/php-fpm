<?php
// comment out the following two lines when deployed to production

defined('YII_DEBUG') or define('YII_DEBUG', true);
defined('YII_ENV') or define('YII_ENV', 'dev');

require __DIR__ . '/../vendor/autoload.php';
require __DIR__ . '/../vendor/yiisoft/yii2/Yii.php';

function yii_application_run() {
	redefine('YII_BEGIN_TIME', microtime(true));

	$config = require __DIR__ . '/../config/web.php';
	(new yii\web\Application($config))->run();
}

function yii_application_clean() {
	rev_close(\Yii::$app);
	\Yii::$app = null;
}

function rev_close(object $obj) {
	if(method_exists($obj, 'getComponents')) {
		foreach($obj->getComponents(false) as $_obj) {
			rev_close($_obj);
		}
	}
	method_exists($obj, 'close') and $obj->close();
}
