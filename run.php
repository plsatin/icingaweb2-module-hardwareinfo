<?php

$this->registerHook('Monitoring\\HostActions', '\\Icinga\\Module\\Hardwareinfo\\HostActions');
$this->registerHook('Monitoring\\ServiceActions', '\\Icinga\\Module\\Hardwareinfo\\ServiceActions');

$this->provideHook('Monitoring\\DetailviewExtension', '\\Icinga\\Module\\Hardwareinfo\\DetailviewExtension');