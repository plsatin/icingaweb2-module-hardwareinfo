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




class DbInventory
{
  //Кдасс взят с этого примера: [Класс для работы с базой данных](https://myrusakov.ru/php-db-class.html)
  //[Паттерны работы с базой данных](https://github.com/codedokode/pasta/blob/master/db/patterns-oop.md)

  private static $db = null; // Единственный экземпляр класса, чтобы не создавать множество подключений
  private $dbconn; // Идентификатор соединения
  private $sym_query = "{?}"; // "Символ значения в запросе"

  /* Получение экземпляра класса. Если он уже существует, то возвращается, если его не было, то создаётся и возвращается (паттерн Singleton) */
  public static function getDB() {
    if (self::$db == null) self::$db = new DbInventory();
    return self::$db;
  }

  /* private-конструктор, подключающийся к базе данных, устанавливающий локаль и кодировку соединения */
  private function __construct() {

    $config = Config::module('hardwareinfo');
    //error_reporting(E_ALL ^ E_DEPRECATED);

    $host = $config->get('db', 'host');
    $database = $config->get('db', 'name');
    $user = $config->get('db', 'user');
    $pswd = $config->get('db', 'password');

    
    $this->dbconn = new Zend_Db_Adapter_Pdo_Mysql(array(
      'host'     => $host,
      'username' => $user,
      'password' => $pswd,
      'dbname'   => $database,
      'charset'  => 'utf8'
    ));
  }

  /* Вспомогательный метод, который заменяет "символ значения в запросе" на конкретное значение, которое проходит через "функции безопасности" */
  private function getQuery($query, $params) {
    if ($params) {
      for ($i = 0; $i < count($params); $i++) {
        $pos = strpos($query, $this->sym_query);
        $arg = "'".$this->dbconn->real_escape_string($params[$i])."'";
        $query = substr_replace($query, $arg, $pos, strlen($this->sym_query));
      }
    }
    return $query;
  }

  /* SELECT-метод, возвращающий таблицу результатов */
  public function select($query, $params = false) {
    // $result_set = $this->dbconn->query($this->getQuery($query, $params));
    // if (!$result_set) return false;
    // return $this->resultSetToArray($result_set);

    $this->dbconn->setFetchMode(Zend_Db::FETCH_OBJ);
    $result = $this->dbconn->fetchAll($query);
    
    if (!$result) return false;
    return $result;


  }

  /* SELECT-метод, возвращающий одну строку с результатом */
  public function selectRow($query, $params = false) {
    $result_set = $this->dbconn->query($this->getQuery($query, $params));
    if ($result_set->num_rows != 1) return false;
    else return $result_set->fetch_assoc();
  }

  /* SELECT-метод, возвращающий значение из конкретной ячейки */
  public function selectCell($query, $params = false) {
    $result_set = $this->dbconn->query($this->getQuery($query, $params));
    if ((!$result_set) || ($result_set->num_rows != 1)) return false;
    else {
      $arr = array_values($result_set->fetch_assoc());
      return $arr[0];
    }
  }

  /* НЕ-SELECT методы (INSERT, UPDATE, DELETE). Если запрос INSERT, то возвращается id последней вставленной записи */
  public function query($query, $params = false) {
    $success = $this->dbconn->query($this->getQuery($query, $params));
    if ($success) {
      if ($this->dbconn->insert_id === 0) return true;
      else return $this->dbconn->insert_id;
    }
    else return false;
  }

  /* Преобразование result_set в двумерный массив */
  private function resultSetToArray($result_set) {
    $array = array();
    while (($row = $result_set->fetch_assoc()) != false) {
      $array[] = $row;
    }
    return $array;
  }

  /* При уничтожении объекта закрывается соединение с базой данных */
  public function __destruct() {
    if ($this->dbconn) $this->dbconn->closeConnection();
  }
}