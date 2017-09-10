<?php


use Icinga\Web\Controller\ModuleActionController;
use Icinga\Application\Icinga;
use Icinga\Web\Controller;
use Icinga\Web\Widget;

use Icinga\Authentication\Auth;



class Hardwareinfo_IndexController extends ModuleActionController
{
    public function indexAction()
    {
        $this->view->tabs = $this->tabs()->activate('index');

    }

    public function treeAction()
    {
        $this->view->tabs = $this->tabs()->activate('tree');
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
                    'url'   => 'hardwareinfo/index/tree'
                )
            );


        } else {

            return Widget::create('tabs')->add(
                'tree',
                array(
                    'label' => $this->translate('Information'),
                    'title' => $this->translate('Hardware Information'),
                    'url'   => 'hardwareinfo/index/tree'
                )
            );


        }
    }

}
