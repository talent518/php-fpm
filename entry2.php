<?php
// comment out the following two lines when deployed to production

defined('YII_ENV') or define('YII_ENV', 'dev');
defined('YII_DEBUG') or define('YII_DEBUG', true);

require __DIR__ . '/../vendor/autoload.php';
require __DIR__ . '/../vendor/yiisoft/yii2/Yii.php';

function yii_application_run() {
	static $time;
	$config = require __DIR__ . '/../config/web.php';
	if(\Yii::$app !== null) {
		\Yii::$app->set('request', \Yii::$app->components['request'] ?? ['class'=>'yii\web\Request']);
		if($time + 600 < time()) {
			syslog(LOG_DEBUG, "TIME");
			rev_close(\Yii::$app);
		}
		\Yii::$app->run();
	} else {
		(new yii\web\Application($config))->run();
	}
	$time = time();
}

function rev_close(object $obj) {
	if(method_exists($obj, 'getComponents')) {
		foreach($obj->getComponents(false) as $_obj) {
			is_object($_obj) and rev_close($_obj);
		}
	}
	method_exists($obj, 'close') and $obj->close();
}
