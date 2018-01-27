<?php

namespace Icinga\Module\Hardwareinfo\Data\Db;

use Icinga\Exception\IcingaException as IE;
use Icinga\Exception\NotFoundError;
use Icinga\Module\Hardwareinfo\Db;

use Exception;
use Zend_Db;
use Zend_Db_Adapter_Abstract;
use Zend_Db_Adapter_Pdo_Mysql;


use Icinga\Application\Config;




abstract class DbObject
{

    public static function getWmiClass($param_host, $ClassId)
    {
      global $config;
      global $dbh;
      
      $config = Config::module('hardwareinfo');
      //error_reporting(E_ALL ^ E_DEPRECATED);
      $errors = array();
      $qhost = $param_host;
      
      $host = $config->get('db', 'host');
      $database = $config->get('db', 'name');
      $user = $config->get('db', 'user');
      $pswd = $config->get('db', 'password');

      $db = new Zend_Db_Adapter_Pdo_Mysql(array(
        'host'     => $host,
        'username' => $user,
        'password' => $pswd,
        'dbname'   => $database,
        'charset'  => 'utf8'
      ));

      $win32class = $ClassId;

      $q_Win32_Class = "SELECT tbInventoryClass.Name AS ClassName, tbInventoryProperty.Name AS PropertyName, tbComputerInventory.Value, tbComputerInventory.InstanceId
      FROM tbComputerInventory INNER JOIN
      tbInventoryClass ON tbComputerInventory.ClassID = tbInventoryClass.ClassID INNER JOIN
      tbInventoryProperty ON tbComputerInventory.PropertyID = tbInventoryProperty.PropertyID INNER JOIN
      tbComputerTarget ON tbComputerInventory.ComputerTargetId = tbComputerTarget.ComputerTargetId
      WHERE  (tbComputerTarget.Name LIKE '%$qhost%' AND tbInventoryClass.ClassID ='$win32class');";
  
 
      $db->setFetchMode(Zend_Db::FETCH_OBJ);
      $result = $db->fetchAll($q_Win32_Class);

      return $result;
    }


}