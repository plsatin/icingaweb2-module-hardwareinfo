<?php
/* Icinga Web 2 | (c) 2016 Icinga Development Team | GPLv2+ */

namespace Icinga\Module\Hardwareinfo;

use Icinga\Application\Config;
use Icinga\Data\Db\DbConnection;

class Db extends DbConnection
{
    public static function newConfiguredInstance()
    {
        return static::fromResourceName(
            Config::module('hardwareinfo')->get('db', 'resource')
        );
    }
}
