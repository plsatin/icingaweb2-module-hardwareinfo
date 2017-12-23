<?php

/** @var \Icinga\Application\Modules\Module $this */

use Icinga\Application\Config;


use Icinga\Authentication\Auth;
$auth = Auth::getInstance();

$this->providePermission(
    'hardwareinfo/hosts',
    $this->translate('Allow unrestricted access to query data in Hardware Information')
);



if ($auth->hasPermission('hardwareinfo/hosts'))
{

    $section = $this->menuSection('Hardware Info', array(
        'url' => 'hardwareinfo',
        'title' => 'Hardware Information',
        'icon' => 'host'
    ));

}



$this->provideConfigTab('Configuration', array(
    'title' => $this->translate('Adjust the general configuration of the hardwareinfo module'),
    'label' => $this->translate('Configuration'),
    'url' => 'config'
));

$this->provideCssFile('jstree/style.css');

//$this->provideJsFile('jstree/jquery.min.js');
$this->provideJsFile('jstree/jstree.min.js');
$this->provideJsFile('jstree/jstree.init.js');

