<?php

namespace Icinga\Module\Hardwareinfo\Web\Tree;

use Icinga\Module\Hardwareinfo\Data\Db\DbInventory;

use Icinga\Web\Url;

/** @var \Icinga\Web\View $this */
/** @var \Icinga\Web\Widget\FilterEditor $filterEditor */
/** @var \Icinga\Module\Monitoring\DataView\DataView $services */
/** @var \Icinga\Web\Url $hostBaseUrl */
/** @var \Icinga\Web\Url $serviceBaseUrl */


define('ICON_DIR', '/icingaweb2/img/hardwareinfo/icons/');




class TreeRender
{

    private $_db = null;
    private $_category_arr = array();

    public function __construct() {
        //Подключаемся к базе данных, и записываем подключение в переменную _db
        $this->_db = DbInventory::getDB(); // Создаём объект базы данных

    }

    public static function renderTree($host)
    {

        $qhost = $host;
        $win32class = 1; //$ClassId;
        $icon_path = ICON_DIR;
        $result = null;

        $q_Hardware_Items = "SELECT tbInventoryClass.Name AS ClassName, tbInventoryProperty.Name AS PropertyName, tbComputerInventory.Value, tbComputerInventory.InstanceId
        FROM tbComputerInventory INNER JOIN
        tbInventoryClass ON tbComputerInventory.ClassID = tbInventoryClass.ClassID INNER JOIN
        tbInventoryProperty ON tbComputerInventory.PropertyID = tbInventoryProperty.PropertyID INNER JOIN
        tbComputerTarget ON tbComputerInventory.ComputerTargetId = tbComputerTarget.ComputerTargetId
        WHERE  (tbComputerTarget.Name LIKE '%$qhost%');";

        $q_Hardware_Class = "SELECT * FROM tbInventoryClass ORDER BY Title";
        // $q_Hardware_Class = "SELECT * FROM tbInventoryClass WHERE ClassID IN (1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 28) ORDER BY Name";



/////////////////////////

        // Закометировать для webnote.satin-pl.com/examples
        $db = DbInventory::getDB(); // Создаём объект базы данных

        // Закометировать для webnote.satin-pl.com/examples
        $hardwareClass = $db->select($q_Hardware_Class);
        $hardwareItems = $db->select($q_Hardware_Items);

        // $hardwareClass = DB::select($q_Hardware_Class);
        // $hardwareItems = DB::select($q_Hardware_Items);

///////////////////////


        if ($hardwareItems == false) {
            return "<ul><li data-jstree='{ \"opened\" : \"true\", \"icon\" : \"".$icon_path."hardware.ico\" }'>Computer: ".$qhost."<ul><li>No data</li></ul></li></ul>";
        }


        $result .= "<ul><li data-jstree='{ \"opened\" : \"true\", \"icon\" : \"".$icon_path."hardware.ico\" }'>Computer: ".$qhost."<ul>";

        // $class_icon = "non-pnp.ico";

        foreach ($hardwareClass as $itemC) {

            $class_icon = $itemC->Icon;

            $result .= "<li data-jstree='{ \"icon\" : \"".$icon_path.$class_icon."\" }'>".$itemC->Title."<ul>";

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
                if ($itemI->ClassName == $itemC->Name) {
                        $i = $itemI->InstanceId;
                        if (!isset($itemIarr[$i])) {
                            $itemIarr[$i] = "";
                            $itemName[$i] = "";
                            $itemCaption[$i] = "";
                            $itemDescription[$i] = "";
                            $itemIcon[$i] = $class_icon;
                        }

                        $itemIarr[$i] .= "<li>".$itemI->PropertyName.": ".$itemI->Value."</li>";
                        if ($itemI->PropertyName == "Name") {
                            $itemName[$i] = $itemI->Value;
                        } elseif ($itemI->PropertyName == "Caption") {
                            $itemCaption[$i] = $itemI->Value;
                        } elseif ($itemI->PropertyName == "Description") {
                            $itemDescription[$i] = $itemI->Value;
                        } elseif ($itemI->PropertyName == "DriveType") {
                            if ($itemI->Value == 5) {
                                $itemIcon[$i] = "cdrom.ico";
                            } elseif ($itemI->Value == 2) {
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

