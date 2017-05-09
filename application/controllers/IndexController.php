<?php


use Icinga\Web\Controller\ModuleActionController;
use Icinga\Application\Icinga;
use Icinga\Web\Controller;
use Icinga\Web\Widget;

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
    }


}
