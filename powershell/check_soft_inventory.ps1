<#
icinga2scripts
Version 1.0
Description: Скрипт для Icinga 2 - Информация о софте рабочей станции

Pavel Satin (c) 2017
pslater.ru@gmail.com
#>
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3

#$ErrorActionPreference = "SilentlyContinue"

$connString = "Server=mysql.server.com;Uid=db_user;Pwd=password;database=inventory;charset=utf8"

if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
    $myFQDN = (Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain

} else {
    $myFQDN = (Get-WmiObject win32_computersystem).DNSHostName
    
}

#Проверка аргументов
if ( $args[0] -ne $Null) {
    $ComputerName = $args[0]
} else {
    $ComputerName = "localhost"
}

if ( $args[1] -ne $Null) {
     $myFQDN = $args[1]
}



#Функция выполнения MySQL запроса
function run-MySQLQuery {
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
			$mySQLDataDLL = "C:\ProgramData\icinga2\Scripts\icinga2\MySQL.Data.dll"
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

} #Конец функции Run-MySQLQuery


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
    $rQLquery = run-MySQLQuery -connectionString $connString -query $sQLquery
    [string]$LastReportedInventoryTime = get-date -Format "yyyy-MM-dd HH:mm:ss"

    if ($rQLquery.ComputerTargetId -ne $Null) {

        $sQLquery = "UPDATE tbComputerTarget SET Name='$myFQDN', LastReportedSoftInventoryTime='$LastReportedInventoryTime' WHERE ComputerTargetId='$ComputerUUID'"
        $rQLquery = run-MySQLQuery -connectionString $connString -query $sQLquery

        $sQLquery = "DELETE FROM tbComputerSoftInventory WHERE ComputerTargetId='$ComputerUUID'"
        $rQLquery = run-MySQLQuery -connectionString $connString -query $sQLquery

    } else {

        $sQLquery = "INSERT INTO tbComputerTarget ( ComputerTargetId, Name, LastReportedSoftInventoryTime ) VALUES ( '$ComputerUUID', '$myFQDN', '$LastReportedInventoryTime' )"
        $rQLquery = run-MySQLQuery -connectionString $connString -query $sQLquery

    }
    ##########################################################################




$recordCount = 0


[string]$Win32ClassName = "Win32_Product"


$computerClassI = Get-WMIObject -Class $Win32ClassName -Computer $ComputerName | Sort-Object InstallDate –Descending
$InstanceId = 0
$SnapshotId = 0

    foreach ($computerClass in $computerClassI) {
        $InstanceId = $InstanceId + 1

            $PropertyName = 901
            $Value = $computerClass.Name

            $sQLDings = "INSERT INTO tbComputerSoftInventory ( ComputerTargetId, PropertyID, Value, InstanceId )
                VALUES ( '$ComputerUUID', '$PropertyName', '$Value', '$InstanceId' )"
            
            run-MySQLQuery -connectionString $connString -query $sQLDings
            $recordCount ++

            $PropertyName = 902
            $Value = $computerClass.Version

            $sQLDings = "INSERT INTO tbComputerSoftInventory ( ComputerTargetId, PropertyID, Value, InstanceId )
                VALUES ( '$ComputerUUID', '$PropertyName', '$Value', '$InstanceId' )"
            
            run-MySQLQuery -connectionString $connString -query $sQLDings
            $recordCount ++

            $PropertyName = 903
            $Value = $computerClass.Vendor

            $sQLDings = "INSERT INTO tbComputerSoftInventory ( ComputerTargetId, PropertyID, Value, InstanceId )
                VALUES ( '$ComputerUUID', '$PropertyName', '$Value', '$InstanceId' )"
            
            run-MySQLQuery -connectionString $connString -query $sQLDings
            $recordCount ++

            $PropertyName = 904
            $Value = $computerClass.InstallDate

            $sQLDings = "INSERT INTO tbComputerSoftInventory ( ComputerTargetId, PropertyID, Value, InstanceId )
                VALUES ( '$ComputerUUID', '$PropertyName', '$Value', '$InstanceId' )"
            
            run-MySQLQuery -connectionString $connString -query $sQLDings
            $recordCount ++

            $PropertyName = 905
            $Value = $computerClass.IdentifyingNumber

            $sQLDings = "INSERT INTO tbComputerSoftInventory ( ComputerTargetId, PropertyID, Value, InstanceId )
                VALUES ( '$ComputerUUID', '$PropertyName', '$Value', '$InstanceId' )"
            
            run-MySQLQuery -connectionString $connString -query $sQLDings
            $recordCount ++


    }




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