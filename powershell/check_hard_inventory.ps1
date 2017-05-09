<#
icinga2scripts
Version 1.0
Description: Скрипт для Icinga 2 - Информация о железе рабочей станции

Pavel Satin (c) 2016
pslater.ru@gmail.com
#>
#[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3

#$ErrorActionPreference = "SilentlyContinue"

$connString = "Server=mysql.server.com;Uid=db_user;Pwd=password;database=inventory;charset=utf8"

$myFQDN = (Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain

#Проверка аргументов
if ( $args[0] -ne $Null) {
    $ComputerName = $args[0]
} else {
    $ComputerName = "localhost"
}

if ( $args[1] -ne $Null) {
     $myFQDN = $args[1]
}




##Не используется в текущей версии
function get-WmiMemoryType {
param ([uint16] $char)

If ($char -ge 0 -and  $char  -le 25) {
        switch ($char) {
            0     {"00-Unknown"}
            1     {"01-Other"}
            2     {"02-DRAM"}
            3     {"03-Synchronous DRAM"}
            4     {"04-Cache DRAM"}
            5     {"05-EDO"}
            6     {"06-EDRAM"}
            7     {"07-VRAM"}
            8     {"08-SRAM"}
            9     {"09-ROM"}
            10     {"10-ROM"}
            11     {"11-FLASH"}
            12     {"12-EEPROM"}
            13     {"13-FEPROM"}
            14     {"14-EPROM"}
            15     {"15-CDRAM"}
            16     {"16-3DRAM"}
            17     {"17-SDRAM"}
            18     {"18-SGRAM"}
            19     {"19-RDRAM"}
            20     {"20-DDR"}
            21     {"21-DDR2"}
            22     {"22-DDR2 FB-DIMM"}
            24     {"24-DDR3"}
            25     {"25-FBD2"}
        }
    } else {
        "{0} - undefined value" -f $char
    }
    Return
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




if ($result) {

$ComputerUUID = get-wmiobject Win32_ComputerSystemProduct -computername $ComputerName | Select-Object -ExpandProperty UUID
$OSSerial = get-wmiobject Win32_OperatingSystem -computername $ComputerName | Select-Object -ExpandProperty SerialNumber

$ComputerUUID = $ComputerUUID + "-" + $OSSerial

<#
$Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
$RegKey= $Reg.OpenSubKey("SOFTWARE\\Microsoft\\Cryptography")
$ComputerGUID = $RegKey.GetValue("MachineGuid")
#>

if ( $ComputerUUID -eq "00000000-0000-0000-0000-000000000000") {
    $ComputerUUID = $ComputerUUID + "-" + $addUUID
} elseif ( $ComputerUUID -eq $Null ) {
    $ComputerUUID = "00000000-0000-0000-0000-000000000000-" + $addUUID
}

<#
if ( $ComputerName -eq "localhost" ) {
    $computerPSVer = $PSVersionTable.psversion
} else {
    $computerPSVer = Invoke-Command  -Computername $ComputerName -Scriptblock {$PSVersionTable.psversion}
}
#>

#Write-Host "Обновляем данные системы в tbComputerTarget"
############################################################################

#$sQLquery = "SELECT ComputerTargetId FROM tbComputerTarget WHERE Name='$ComputerName'"
$sQLquery = "SELECT Name, ComputerTargetId FROM tbComputerTarget WHERE ComputerTargetId='$ComputerUUID'"
$rQLquery = run-MySQLQuery -connectionString $connString -query $sQLquery
[string]$LastReportedInventoryTime = get-date -Format "yyyy-MM-dd HH:mm:ss"

if ($rQLquery.ComputerTargetId -ne $Null) {

    #$sQLquery = "UPDATE tbComputerTarget SET ComputerTargetId='$ComputerUUID', LastReportedInventoryTime='$LastReportedInventoryTime' WHERE Name='$ComputerName'"
    $sQLquery = "UPDATE tbComputerTarget SET Name='$myFQDN', LastReportedInventoryTime='$LastReportedInventoryTime' WHERE ComputerTargetId='$ComputerUUID'"
    $rQLquery = run-MySQLQuery -connectionString $connString -query $sQLquery

    $sQLquery = "DELETE FROM tbComputerInventory WHERE ComputerTargetId='$ComputerUUID'"
    $rQLquery = run-MySQLQuery -connectionString $connString -query $sQLquery
} else {

    $sQLquery = "INSERT INTO tbComputerTarget ( ComputerTargetId, Name, LastReportedInventoryTime ) VALUES ( '$ComputerUUID', '$myFQDN', '$LastReportedInventoryTime' )"
    $rQLquery = run-MySQLQuery -connectionString $connString -query $sQLquery
}
##########################################################################



$sQLquery = "SELECT ClassID, Name FROM tbInventoryClass"
$rQLquery = run-MySQLQuery -connectionString $connString -query $sQLquery

$recordCount = 0

foreach ($row in $rQLquery) {

[string]$Win32ClassName = $row.Name
$Win32ClassID = $row.ClassID

##Отладочный вывод названия обрабатываемого класса ###############################################################
#Write-Host $Win32ClassName

$computerClassI = Get-WMIObject -Class $Win32ClassName -Computer $ComputerName
$InstanceId = 0

    foreach ($computerClass in $computerClassI) {
        $InstanceId = $InstanceId + 1
        $ClassName = $Win32ClassName

        $sQLqueryProp = "SELECT PropertyID, ClassID, Name FROM tbInventoryProperty WHERE ClassID='$Win32ClassID'"
        $rQLqueryProp = run-MySQLQuery -connectionString $connString -query $sQLqueryProp
        
        foreach ($rowProp in $rQLqueryProp) {
            $PropertyID = $rowProp.PropertyID
            $PropertyName = $rowProp.Name
            $Value = $computerClass.$PropertyName

            $sQLDings = "INSERT INTO tbComputerInventory ( ComputerTargetId, ClassID, PropertyID, Value, InstanceId )
                VALUES ( '$ComputerUUID', '$Win32ClassID', '$PropertyID', '$Value', '$InstanceId' )"
            
            run-MySQLQuery -connectionString $connString -query $sQLDings
            $recordCount ++
        }
    }


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