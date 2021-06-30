<?php


namespace Icinga\Module\Hardwareinfo\Forms\Config;

use Exception;
use Icinga\Data\ResourceFactory;
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
        $resources = array();
        foreach (ResourceFactory::getResourceConfigs() as $name => $config) {
            if ($config->type === 'db') {
                $resources[] = $name;
            }
        }

        $this->addElement(
            'select',
            'db_resource',
            array(
                'description'   => $this->translate('The resource to use'),
                'label'         => $this->translate('Resource'),
                'multiOptions'  => array_combine($resources, $resources),
                'required'      => true
            )
        );

        if (isset($formData['skip_validation']) && $formData['skip_validation']) {
            $this->addSkipValidationCheckbox();
        }
    }

}
