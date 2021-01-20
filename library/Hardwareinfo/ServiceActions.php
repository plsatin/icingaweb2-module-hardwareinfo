<?php
namespace Icinga\Module\Hardwareinfo;

use Icinga\Module\Monitoring\Object\Host;
use Icinga\Module\Monitoring\Object\Service;
use Icinga\Module\Monitoring\Web\Hook\ServiceActionsHook;
use Icinga\Web\Url;

class ServiceActions extends ServiceActionsHook
{
    public function getActionsForService(Service $service)
    {
        $elements = array();
        
        if ($service->getName() == "hardware-inventory") {
            $elements = array();
            $elements[mt('hardwareinfo', 'Hardware Information')] = array('url'  => Url::fromPath('hardwareinfo/tree', array('host' => $service->getHost()->getName())),
            'icon' => 'host',
            
            );
        }
        if ($service->getName() == "hardware-inventory-cycle2") {
            $elements = array();
            $elements[mt('hardwareinfo', 'Hardware Information')] = array('url'  => Url::fromPath('hardwareinfo/tree', array('host' => $service->getHost()->getName())),
            'icon' => 'host',
            
            );
        }
        if ($service->getName() == "hardware-inventory-cycle3") {
            $elements = array();
            $elements[mt('hardwareinfo', 'Hardware Information')] = array('url'  => Url::fromPath('hardwareinfo/tree', array('host' => $service->getHost()->getName())),
            'icon' => 'host',
            
            );
        }
        if ($service->getName() == "inventory-cycle") {
            $elements = array();
            $elements[mt('hardwareinfo', 'Hardware Information')] = array('url' => Url::fromPath('hardwareinfo/tree',
                array('host' => $service->getHost()->getName())),
                'icon' => 'host',
            );
            $elements[mt('softwareinfo', 'Software Report')] = array('url' => Url::fromPath('/icingaweb2/iframe?url=/reports/SoftwareByHost.php?host='.$service->getHost()->getName()),
                'icon' => 'doc-text', );
            $elements[mt('updatesinfo', 'Updates Report')] = array('url' => Url::fromPath('/icingaweb2/iframe?url=/reports/UpdatesByHost.php?host='.$service->getHost()->getName()),
                'icon' => 'doc-text', );
        }



        return $this->createNavigation($elements);

    }
}