<?php

namespace Icinga\Module\Hardwareinfo\Controllers;

use Icinga\Module\Hardwareinfo\Data\Db\DbObject;
use Icinga\Module\Hardwareinfo\Web\Tree\TreeRender;

use Icinga\Module\Hardwareinfo\Web\Controller\MonitoringAwareController;
use Icinga\Module\Monitoring\DataView\DataView;
use Icinga\Data\Filter\Filter;
use Icinga\Web\Url;
use Icinga\Web\Controller\ModuleActionController;
use Icinga\Application\Icinga;
use Icinga\Web\Controller;
use Icinga\Web\Widget;
use Icinga\Authentication\Auth;


class TreeController extends MonitoringAwareController
{
    public function init()
    {
        $this->view->hostBaseUrl = $hostBaseUrl = $this->_request->getBaseUrl();
        $this->view->baseUrl = $baseUrl = Url::fromPath('hatdwareinfo/tree');
        $this->view->paramUrl = $paramUrl = $this->getRequest()->getUrl()->getParams();
        
    }

    // public function oldAction()
    // {

    //     $this->view->controller = $this;

    //     $this->view->treehost = $treehost = $this->getRequest()->getUrl()->getParam('host');
    //     if ($treehost != null) {
    //         $this->view->r_Win32_OperatingSystem = $r_Win32_OperatingSystem = DbObject::getWmiClass($treehost, 8);
    //         $this->view->r_Win32_ComputerSystem = $r_Win32_ComputerSystem = DbObject::getWmiClass($treehost, 2);
    //         $this->view->r_Win32_BaseBoard = $r_Win32_BaseBoard = DbObject::getWmiClass($treehost, 16);
    //         $this->view->r_Win32_BIOS = $r_Win32_BIOS = DbObject::getWmiClass($treehost, 1);
    //         $this->view->r_Win32_Processor = $r_Win32_Processor = DbObject::getWmiClass($treehost, 11);
    //         $this->view->r_Win32_PhysicalMemoryArray = $r_Win32_PhysicalMemoryArray = DbObject::getWmiClass($treehost, 28);
    //         $this->view->r_Win32_PhysicalMemory = $r_Win32_PhysicalMemory = DbObject::getWmiClass($treehost, 15);
    //         $this->view->r_Win32_DiskDrive = $r_Win32_DiskDrive = DbObject::getWmiClass($treehost, 4);
    //         $this->view->r_Win32_LogicalDisk = $r_Win32_LogicalDisk = DbObject::getWmiClass($treehost, 5);
    //         $this->view->r_Win32_IDEController = $r_Win32_IDEController = DbObject::getWmiClass($treehost, 17);
    //         $this->view->r_Win32_SCSIController = $r_Win32_SCSIController = DbObject::getWmiClass($treehost, 18);
    //         $this->view->r_Win32_USBController = $r_Win32_USBController = DbObject::getWmiClass($treehost, 19);
    //         $this->view->r_Win32_USBHub = $r_Win32_USBHub = DbObject::getWmiClass($treehost, 20);
    //         $this->view->r_Win32_PointingDevice = $r_Win32_PointingDevice = DbObject::getWmiClass($treehost, 21);
    //         $this->view->r_Win32_Keyboard = $r_Win32_Basr_Win32_KeyboardeBoard = DbObject::getWmiClass($treehost, 22);
    //         $this->view->r_Win32_SerialPort = $r_Win32_SerialPort = DbObject::getWmiClass($treehost, 23);
    //         $this->view->r_Win32_ParallelPort = $r_Win32_ParallelPort = DbObject::getWmiClass($treehost, 24);
    //         $this->view->r_Win32_NetworkAdapter = $r_Win32_NetworkAdapter = DbObject::getWmiClass($treehost, 6);
    //         $this->view->r_Win32_NetworkAdapterConfiguration = $r_Win32_NetworkAdapterConfiguration = DbObject::getWmiClass($treehost, 7);
    //         $this->view->r_Win32_VideoController = $r_Win32_VideoController = DbObject::getWmiClass($treehost, 13);
    //         $this->view->r_Win32_DesktopMonitor = $r_Win32_DesktopMonitor = DbObject::getWmiClass($treehost, 3);
    //         $this->view->r_Win32_SoundDevice = $r_Win32_SoundDevice = DbObject::getWmiClass($treehost, 12);
    //         $this->view->r_Win32_Printer = $r_Win32_Printer = DbObject::getWmiClass($treehost, 10);




    //     } else {
    //         echo 'The parameter is not set ?host';
    //     }


    //     //$this->view->tabs = $this->tabs()->activate('tree');

    // }

    public function indexAction()
    {

        $this->view->treehost = $treehost = $this->getRequest()->getUrl()->getParam('host');

        $this->view->r_AllClass = $r_AllClass = TreeRender::renderTree($treehost);
        

    }



    protected function tabs()
    {
        $auth = Auth::getInstance();
        
        if ($auth->hasPermission('hardwareinfo/hosts'))
        {


            return Widget::create('tabs')->add(
                'index',
                array(
                    'label' => $this->translate('Hosts'),
                    'url'   => 'hardwareinfo'
                )
            )->add(
                'tree',
                array(
                    'label' => $this->translate('Information'),
                    'title' => $this->translate('Hardware Information'),
                    'url'   => 'hardwareinfo/tree'
                )
            );


        } else {

            return Widget::create('tabs')->add(
                'tree',
                array(
                    'label' => $this->translate('Information'),
                    'title' => $this->translate('Hardware Information'),
                    'url'   => 'hardwareinfo/tree'
                )
            );


        }
    }




    /**
     * Apply filters on a DataView
     *
     * @param DataView  $dataView       The DataView to apply filters on
     */
    protected function filterQuery(DataView $dataView)
    {
        $this->setupFilterControl(
            $dataView,
            null,
            null,
            array_merge(['format', 'stateType', 'addColumns', 'problems']
        ));
        $this->handleFormatRequest($dataView);
    }

}