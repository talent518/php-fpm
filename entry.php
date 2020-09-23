<?php
// comment out the following two lines when deployed to production

defined('YII_ENV') or define('YII_ENV', false);
defined('YII_DEBUG') or define('YII_DEBUG', true);

require __DIR__ . '/../vendor/autoload.php';
require __DIR__ . '/../vendor/yiisoft/yii2/Yii.php';

function yii_application_run() {
	if(0) {
		$vars = [];
		foreach(['_SERVER','_GET','_POST','_REQUEST','_ENV','_FILES','_COOKIE'] as $var) {
			$vars[$var] = &$GLOBALS[$var];
		}
		echo json_encode($vars, JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
	} else {
		$config = require __DIR__ . '/../config/web.php';
		(new yii\web\Application($config))->run();
		rev_close(\Yii::$app);
		\Yii::$app = null;
	}
}

function rev_close(object $obj) {
	if(method_exists($obj, 'getComponents')) {
		foreach($obj->getComponents(false) as $_obj) {
			is_object($_obj) and rev_close($_obj);
		}
	}
	method_exists($obj, 'close') and $obj->close();
}
