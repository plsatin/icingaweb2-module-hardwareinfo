﻿<#
 .SYNOPSIS
  Сбор информации об аппаратном обеспечении через WMI. 


 .DESCRIPTION


 .PARAMETER ComputerName
  Имя компьютера

 .PARAMETER myFQDN
  Полное доменное имя (указанное как host.name в Icinga2)

 .OUTPUTS
  

 .EXAMPLE
  

 .LINK 
  https://webnote.satin-pl.com

 .NOTES
  Version:        0.1
  Author:         Pavel Satin
  Email:          plsatin@yandex.ru
  Creation Date:  <Date>
  Purpose/Change: Initial script development

#>
Param(
    [Parameter(Mandatory = $false)]
        [string]$ComputerName = "localhost",   
    [Parameter(Mandatory = $false)]
        [string]$myFQDN
    )

#[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3

#$ErrorActionPreference = "SilentlyContinue"

$connString = "Server=icinga2.satin-pl.com;Uid=inventory_user;Pwd=Z123456z;database=inventory;charset=utf8"

if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
    $myFQDN = (Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain

} else {
    $myFQDN = (Get-WmiObject win32_computersystem).DNSHostName
    
}




#Функция выполнения MySQL запроса
function Invoke-MySQLQuery {
	Param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = '',
            ValueFromPipeline = $true)]
            [string]$query,   
		[Parameter(
            Mandatory = $true,
            ParameterSetName = '',
            ValueFromPipeline = $true)]
            [string]$connectionString
        )

		try {
			# load MySQL driver and create connection
			Write-Verbose "Create Database Connection"
			# You could also could use a direct Link to the DLL File
			$mySQLDataDLL = "C:\ProgramData\icinga2\Scripts\icinga2\bin\MySQL.Data.dll"
			[void][system.reflection.Assembly]::LoadFrom($mySQLDataDLL)
			#[void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
			$connection = New-Object MySql.Data.MySqlClient.MySqlConnection
			$connection.ConnectionString = $ConnectionString
			Write-Verbose "Open Database Connection"
			$connection.Open()
			
			# Run MySQL Querys
			Write-Verbose "Run MySQL Querys"
			$command = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $connection)
			$dataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($command)
			$dataSet = New-Object System.Data.DataSet
			$recordCount = $dataAdapter.Fill($dataSet, "data")
			$dataSet.Tables["data"] # | Format-Table
		}		
		catch {
			Write-Host "Could not run MySQL Query" $Error[0]	
		}	
		Finally {
			Write-Verbose "Close Connection"
			$connection.Close()
		}

} #Конец функции Invoke-MySQLQuery


#########################################################################################
#Замер времени исполнения скрипта
$watch = [System.Diagnostics.Stopwatch]::StartNew()
$watch.Start() #Запуск таймера

if ($ComputerName -eq ".") {
	$result = $true
    $addUUID = $myFQDN
} elseif ( $ComputerName -eq "localhost" ) {
	$result = $true
    $addUUID = $myFQDN
    $ComputerName = $myFQDN
} else {
    $addUUID = $ComputerName
    $myFQDN = $ComputerName
	$result = Test-Connection -ComputerName $ComputerName -Count 2 -Quiet
}


$myFQDN = $myFQDN.ToLower()


if ($result) {

    $ComputerUUID = get-wmiobject Win32_ComputerSystemProduct -computername $ComputerName | Select-Object -ExpandProperty UUID
    $OSSerial = get-wmiobject Win32_OperatingSystem -computername $ComputerName | Select-Object -ExpandProperty SerialNumber

    $ComputerUUID = $ComputerUUID + "-" + $OSSerial

    if ( $ComputerUUID -eq "00000000-0000-0000-0000-000000000000") {
        $ComputerUUID = $ComputerUUID + "-" + $addUUID
    } elseif ( $ComputerUUID -eq $Null ) {
        $ComputerUUID = "00000000-0000-0000-0000-000000000000-" + $addUUID
    }


    #Write-Host "Обновляем данные системы в tbComputerTarget"
    ############################################################################

    $sQLquery = "SELECT Name, ComputerTargetId FROM tbComputerTarget WHERE ComputerTargetId='$ComputerUUID'"
    $rQLquery = Invoke-MySQLQuery -connectionString $connString -query $sQLquery
    [string]$LastReportedInventoryTime = get-date -Format "yyyy-MM-dd HH:mm:ss"

    if ($rQLquery.ComputerTargetId -ne $Null) {

        $sQLquery = "UPDATE tbComputerTarget SET Name='$myFQDN', LastReportedInventoryTime='$LastReportedInventoryTime' WHERE ComputerTargetId='$ComputerUUID'"
        $rQLquery = Invoke-MySQLQuery -connectionString $connString -query $sQLquery


    } else {

        $sQLquery = "INSERT INTO tbComputerTarget ( ComputerTargetId, Name, LastReportedInventoryTime ) VALUES ( '$ComputerUUID', '$myFQDN', '$LastReportedInventoryTime' )"
        $rQLquery = Invoke-MySQLQuery -connectionString $connString -query $sQLquery

    }
    ##########################################################################

    ##Отладочный вывод ###############################################################
    #Write-Host "Inventory of hardware ..."


    #Выбираем только включенные классы
    $sQLquery = "SELECT ClassID, Name, Namespace, Enabled FROM tbInventoryClass WHERE Enabled = 1"
    $rQLquery = Invoke-MySQLQuery -connectionString $connString -query $sQLquery

    $recordCount = 0

    foreach ($row in $rQLquery) {



        [string]$Win32ClassName = $row.Name
        $Win32ClassID = $row.ClassID
        
        #Удаляем старые записи этого класса
        $sQLqueryDel = "DELETE FROM tbComputerInventory WHERE (ComputerTargetId='$ComputerUUID' AND ClassID = $Win32ClassID)"
        $rQLqueryDel = Invoke-MySQLQuery -connectionString $connString -query $sQLqueryDel
        
        
        ##Отладочный вывод названия обрабатываемого класса ###############################################################
        #Write-Host $Win32ClassName

        [string]$Win32Namespace = $row.Namespace
        $computerClassI = Get-WMIObject -Namespace $Win32Namespace -Class $Win32ClassName -Computer $ComputerName

        $InstanceId = 0

        
        foreach ($computerClass in $computerClassI) {
            $InstanceId = $InstanceId + 1
        
            $sQLqueryProp = "SELECT PropertyID, ClassID, Name FROM tbInventoryProperty WHERE ClassID='$Win32ClassID'"
            $rQLqueryProp = Invoke-MySQLQuery -connectionString $connString -query $sQLqueryProp
                
            foreach ($rowProp in $rQLqueryProp) {
                $PropertyID = $rowProp.PropertyID
                $PropertyName = $rowProp.Name
                $Value = $computerClass.$PropertyName
        
                $sQLDings = "INSERT INTO tbComputerInventory ( ComputerTargetId, ClassID, PropertyID, Value, InstanceId )
                        VALUES ( '$ComputerUUID', '$Win32ClassID', '$PropertyID', '$Value', '$InstanceId' )"
                    
                Invoke-MySQLQuery -connectionString $connString -query $sQLDings
                $recordCount ++

            }
        }


    }

    #Write-Host "---------------------------------------------"
    Write-Host "Inserted $recordCount entries in the database"

    $watch.Stop() #Остановка таймера
    Write-Host $watch.Elapsed #Время выполнения
    Write-Host (Get-Date)
    [System.Environment]::Exit($returnStateOK)

} #End if test-connection result
else {
    Write-Host "Host $ComputerName is not available."
	[System.Environment]::Exit($returnStateUnknown)
}