<?php

/** @var \Icinga\Application\Modules\Module $this */

use Icinga\Application\Config;

$section = $this->menuSection('Hardware Info', array(
    'url' => 'hardwareinfo',
    'title' => 'Hardware Information',
    'icon' => 'host'
));

$this->provideConfigTab('Configuration', array(
    'title' => $this->translate('Adjust the general configuration of the hardwareinfo module'),
    'label' => $this->translate('Configuration'),
    'url' => 'config'
));

$this->provideCssFile('jstree/style.css');
//$this->provideJsFile('jstree/jstree.min.js');
//$this->provideJsFile('jstree/jstree.init.js');

