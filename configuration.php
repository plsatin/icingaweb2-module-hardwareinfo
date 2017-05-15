<?php

/** @var \Icinga\Application\Modules\Module $this */

use Icinga\Application\Config;

$section = $this->menuSection('Hardware Info', array(
    'url' => 'hardwareinfo',
    'title' => 'Hardware Information',
    'icon' => 'host'
));

$this->provideConfigTab('general', array(
    'title' => $this->translate('Adjust the general configuration of the hardwareinfo module'),
    'label' => $this->translate('General'),
    'url' => 'config'
));

//$this->provideCssFile('jstree/default/style.min.css');
//$this->provideJsFile('jstree/jstree.min.js');


//
//$this->provideCssFile('/icingaweb2/plsatin/css/icons.css');