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
            $elements[mt('hardwareinfo', 'Hardware Information')] = array('url'  => Url::fromPath('hardwareinfo/index/tree', array('q' => $service->getHost()->getName())),
            'icon' => 'host',
            
            );
        } elseif ($service->getName() == "hardware-inventory-system") {
            $elements = array();
            $elements[mt('hardwareinfo', 'Hardware Information')] = array('url'  => Url::fromPath('hardwareinfo/index/tree', array('q' => $service->getHost()->getName())),
            'icon' => 'host',
            
            );
        } elseif ($service->getName() == "hardware-inventory-endpoint") {
            $elements = array();
            $elements[mt('hardwareinfo', 'Hardware Information')] = array('url'  => Url::fromPath('hardwareinfo/index/tree', array('q' => $service->getHost()->getName())),
            'icon' => 'host',
            
            );
        }



        return $this->createNavigation($elements);

    }
}