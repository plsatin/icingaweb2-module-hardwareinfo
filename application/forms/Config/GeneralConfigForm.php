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
            'select',
            'db_adapter',
            array(
                'value'         => 'PDO_MYSQL',
                'label'         => $this->translate('Database type'),
                'multiOptions'  => array (
                    'PDO_MYSQL'     => $this->translate('PDO_MYSQL'),
                    ),
                'description'   => $this->translate('The type of the database.')
            )
        );

        $this->addElement(
            'text',
            'db_host',
            array(
                'value'         => 'localhost',
                'label'         => $this->translate('Host'),
                'requirement'   => $this->translate('The hostname of the database.')
            )
        );

        $this->addElement(
            'text',
            'db_name',
            array(
                'value'         => 'inventory',
                'label'         => $this->translate('Database'),
                'requirement'   => $this->translate('The name of the database.')
            )
        );

        $this->addElement(
            'text',
            'db_user',
            array(
                'value'         => 'inventory',
                'label'         => $this->translate('User'),
                'requirement'   => $this->translate('The user of the database.')
            )
        );

        $this->addElement(
            'password',
            'db_password',
            array(
                'renderPassword'=> true,
                'value'         => '',
                'label'         => $this->translate('Password'),
                'requirement'   => $this->translate('The user passsword of the database.')
            )
        );


    }
}
