<?php
namespace Icinga\Module\Hardwareinfo;
use Icinga\Module\Monitoring\Web\Hook\HostActionsHook;
use Icinga\Module\Monitoring\Object\Host;
use Icinga\Web\Url;

class HostActions extends HostActionsHook
{
    public function getActionsForHost(Host $host)
    {
        
        $elements = array();
        $elements[mt('hardwareinfo', 'Hardware Information')] = array('url' => Url::fromPath('hardwareinfo/tree',
            array('host' => $host->getName())),
            'icon' => 'host',
        );
        $elements[mt('softwareinfo', 'Software Report')] = array('url' => Url::fromPath('/icingaweb2/iframe?url=/reports/SoftwareByHost.php?host='.$host->getName()),
            'icon' => 'doc-text', 'data-base-target' => "_self",
        );
        $elements[mt('updatesinfo', 'Updates Report')] = array('url' => Url::fromPath('/icingaweb2/iframe?url=/reports/UpdatesByHost.php?host='.$host->getName()),
            'icon' => 'doc-text', 'data-base-target' => "_self",
        );

        return $this->createNavigation($elements);

    }
   

}