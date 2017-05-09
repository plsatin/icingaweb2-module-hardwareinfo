<?php


namespace Icinga\Module\Hardwareinfo\Forms\Config;

use Icinga\Forms\ConfigForm;

class GeneralConfigForm extends ConfigForm
{

    public function init()
    {
        $this->setName('form_config_hardwareinfo_general');
        $this->setSubmitLabel($this->translate('Save Changes'));
    }

    public function createElements(array $formData)
    {

        $this->addElement(
            'text',
            'db_host',
            array(
                'value'         => 'localhost',
                'label'         => $this->translate('Host'),
                //'description'   => $this->translate('DB Host'),
                'requirement'   => $this->translate('The hostname of the database.')
            )
        );

        $this->addElement(
            'text',
            'db_name',
            array(
                'value'         => 'inventory',
                'label'         => $this->translate('Database'),
                //'description'   => $this->translate('Database Name'),
                'requirement'   => $this->translate('The name of the database.')
            )
        );

        $this->addElement(
            'text',
            'db_user',
            array(
                'value'         => 'inventory',
                'label'         => $this->translate('User'),
                //'description'   => $this->translate('Database User'),
                'requirement'   => $this->translate('The user of the database.')
            )
        );

        $this->addElement(
            'text',
            'db_password',
            array(
                'value'         => '',
                'label'         => $this->translate('Password'),
                //'description'   => $this->translate('Database User Password'),
                'requirement'   => $this->translate('The user passsword of the database.')
            )
        );


    }
}
