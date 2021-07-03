<?php
namespace Icinga\Module\Hardwareinfo\Web\Tree;

// use Icinga\Module\Hardwareinfo\Data\Db\DbInventory;
use Icinga\Module\Hardwareinfo\Db;

use Icinga\Web\Url;

/** @var \Icinga\Web\View $this */
/** @var \Icinga\Web\Widget\FilterEditor $filterEditor */
/** @var \Icinga\Module\Monitoring\DataView\DataView $services */
/** @var \Icinga\Web\Url $hostBaseUrl */
/** @var \Icinga\Web\Url $serviceBaseUrl */


define('ICON_DIR', '/icingaweb2/img/hardwareinfo/icons/');

class TreeRender
{

    public static function renderTree($host)
    {
        $qhost = $host;
        $win32class = 1; //$ClassId;
        $icon_path = ICON_DIR;
        $result = null;

        // $q_Hardware_Items = "SELECT tbInventoryClass.Name AS ClassName, tbInventoryProperty.Name AS PropertyName, tbComputerInventory.Value, tbComputerInventory.InstanceId
        // FROM tbComputerInventory INNER JOIN
        // tbInventoryClass ON tbComputerInventory.ClassID = tbInventoryClass.ClassID INNER JOIN
        // tbInventoryProperty ON tbComputerInventory.PropertyID = tbInventoryProperty.PropertyID INNER JOIN
        // tbComputerTarget ON tbComputerInventory.ComputerTargetId = tbComputerTarget.ComputerTargetId
        // WHERE  (tbComputerTarget.Name LIKE '%$qhost%');";

        // $q_Hardware_Class = "SELECT * FROM tbInventoryClass ORDER BY Title";

        $db = Db::newConfiguredInstance();

        $queryClass = $db->select();
        $queryClass->from('tbInventoryClass',
            array(
                'ClassID',
                'Name',
                'Namespace',
                'Title',
                'Description',
                'Icon',
                'Enabled'
        ));
        $queryClass->order('Title');
        $hardwareClass = $queryClass->fetchAll();


        $queryItems = $db->select()
        ->from(array('i' => 'tbComputerInventory'),
            array('ClassName' => 'c.Name', 'PropertyName' => 'p.Name', 'Value', 'InstanceId'))
            ->join(array('c' => 'tbInventoryClass'), 'i.ClassID = c.ClassID')
                ->join(array('p' => 'tbInventoryProperty'), 'i.PropertyID = p.PropertyID')
                    ->join(array('t' => 'tbComputerTarget'), 'i.ComputerTargetId = t.ComputerTargetId')
                        ->where('t.Name', $qhost); 
        $hardwareItems = $queryItems->fetchAll();


        if ($hardwareItems == false) {
            return "<ul><li data-jstree='{ \"opened\" : \"true\", \"icon\" : \"".$icon_path."hardware.ico\" }'>Computer: ".$qhost."<ul><li>No data</li></ul></li></ul>";
        }


        $result .= "<ul><li data-jstree='{ \"opened\" : \"true\", \"icon\" : \"".$icon_path."hardware.ico\" }'>Computer: ".$qhost."<ul>";


        foreach ($hardwareClass as $itemC) {
            $itemC = get_object_vars($itemC);
            $class_icon = $itemC['icon'];

            $result .= "<li data-jstree='{ \"icon\" : \"".$icon_path.$class_icon."\" }'>".$itemC['title']."<ul>";

            $itemIarr = array();
            $itemName = array();
            $itemCaption = array();
            $itemDescription = array();
            $itemIcon = array();

            $itemIarr[0] = "";
            $itemName[0] = "";
            $itemCaption[0] = "";
            $itemDescription[0] = "";
            $itemIcon[0] = "";

            foreach ($hardwareItems as $itemI) {
                $itemI = get_object_vars($itemI);
                if ($itemI['classname'] == $itemC['name']) {
                    $i = $itemI['instanceid'];
                    if (!isset($itemIarr[$i])) {
                        $itemIarr[$i] = "";
                        $itemName[$i] = "";
                        $itemCaption[$i] = "";
                        $itemDescription[$i] = "";
                        $itemIcon[$i] = $class_icon;
                    }

                    $itemIarr[$i] .= "<li>".$itemI['propertyname'].": ".$itemI['value']."</li>";
                    if ($itemI['propertyname'] == "Name") {
                        $itemName[$i] = $itemI['value'];
                    } elseif ($itemI['propertyname'] == "Caption") {
                        $itemCaption[$i] = $itemI['value'];
                    } elseif ($itemI['propertyname'] == "Description") {
                        $itemDescription[$i] = $itemI['value'];
                    } elseif ($itemI['propertyname'] == "DriveType") {
                        if ($itemI['value'] == 5) {
                            $itemIcon[$i] = "cdrom.ico";
                        } elseif ($itemI['value'] == 2) {
                            $itemIcon[$i] = "disk-usb.ico";
                        }
                    }
                }

            }

            $i = 0;
            foreach ($itemIarr as $itemIa) {
                if ($itemIa != "") {
                    if (!isset($itemName[$i])) {
                        $itemName[$i] = "";
                    }
                    if (!isset($itemCaption[$i])) {
                        $itemCaption[$i] = "";
                    }
                    if (!isset($itemDescription[$i])) {
                        $itemDescription[$i] = "";
                    }
                    if (!isset($itemIcon[$i])) {
                        $itemIcon[$i] = $class_icon;
                    }

                    if ($itemName[$i] == "") {
                        if ($itemCaption[$i] == "") {
                            $itemName[$i] = $itemDescription[$i];
                        } else {
                            $itemName[$i] = $itemCaption[$i];
                        }
                    }

                    $result .= "<li data-jstree='{ \"icon\" : \"".$icon_path.$itemIcon[$i]."\" }'>".$itemName[$i]."<ul>";
                    $result .= $itemIa;
                    $result .= "</ul></li>";
                }
                $i ++;
            }
            $result .= "</ul></li>"; //Конец класса
        }
        $result .= "</ul></li></ul>"; //Конец дерева
        return $result;
    }

}

