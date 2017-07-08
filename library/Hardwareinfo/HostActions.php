<?php
namespace Icinga\Module\Hardwareinfo;
use Icinga\Module\Monitoring\Web\Hook\HostActionsHook;
use Icinga\Module\Monitoring\Object\Host;
use Icinga\Web\Url;
class HostActions extends HostActionsHook
{
    public function getActionsForHost(Host $host)
    {
        return $this->createNavigation(array(
            mt('hardwareinfo', 'Hardware Information') => array(
                'url'  => Url::fromPath('hardwareinfo/index/tree', array('q' => $host->getName())),
                'icon' => 'host',
                
            )
        ));
    }
}