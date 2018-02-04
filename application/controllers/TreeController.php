<?php

namespace Icinga\Module\Hardwareinfo\Controllers;

use Icinga\Module\Hardwareinfo\Web\Tree\TreeRender;

use Icinga\Module\Hardwareinfo\Web\Controller\MonitoringAwareController;
use Icinga\Module\Monitoring\DataView\DataView;
use Icinga\Web\Url;


class TreeController extends MonitoringAwareController
{
    public function init()
    {
        // $this->view->hostBaseUrl = $hostBaseUrl = $this->_request->getBaseUrl();
        // $this->view->baseUrl = $baseUrl = Url::fromPath('hatdwareinfo/tree');
        // $this->view->paramUrl = $paramUrl = $this->getRequest()->getUrl()->getParams();
        
    }

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




    // /**
    //  * Apply filters on a DataView
    //  *
    //  * @param DataView  $dataView       The DataView to apply filters on
    //  */
    // protected function filterQuery(DataView $dataView)
    // {
    //     $this->setupFilterControl(
    //         $dataView,
    //         null,
    //         null,
    //         array_merge(['format', 'stateType', 'addColumns', 'problems']
    //     ));
    //     $this->handleFormatRequest($dataView);
    // }

}