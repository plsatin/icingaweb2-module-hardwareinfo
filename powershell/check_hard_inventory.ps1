<#
 .SYNOPSIS
  Сбор информации об аппаратном обеспечении через WMI.


 .DESCRIPTION


 .PARAMETER ComputerName
  Имя компьютера

 .PARAMETER myFQDN
  Полное доменное имя (указанное как host.name в Icinga2)

 .OUTPUTS


 .EXAMPLE
check_hard_inventory.ps1

Inserted 338 entries in the database
00:00:24.7797134
19.02.2018 13:37:55

 .EXAMPLE
check_hard_inventory.ps1 -Verbose

ПОДРОБНО: Выполняется загрузка модуля с использованием пути
"C:\ProgramData\icinga2\Scripts\icinga2\icinga2scripts.psm1".
ПОДРОБНО: Импорт функции "Get-ComputerUUID".
ПОДРОБНО: Импорт функции "Get-Icinga2HostState".
ПОДРОБНО: Импорт функции "Get-Icinga2ServiceState".
ПОДРОБНО: Импорт функции "Invoke-MySQLQuery".
ПОДРОБНО: Импорт функции "Send-Icinga2HostVars".
ПОДРОБНО:
ПОДРОБНО: ts01e.pshome.local
ПОДРОБНО: ComputerUUID: C238D1CE-5477-4983-B472-ACB3592BE325-00252-70000-00000-AA064
ПОДРОБНО: Обновляем данные системы в tbComputerTarget
ПОДРОБНО: Inventory of hardware ...
ПОДРОБНО: Win32_BIOS
ПОДРОБНО: Win32_ComputerSystem
ПОДРОБНО: Win32_DesktopMonitor
ПОДРОБНО: Win32_DiskDrive
ПОДРОБНО: Win32_LogicalDisk
ПОДРОБНО: Win32_OperatingSystem
ПОДРОБНО: Win32_Printer
ПОДРОБНО: Win32_Processor
ПОДРОБНО: Win32_SoundDevice
ПОДРОБНО: Win32_VideoController
ПОДРОБНО: Win32_PhysicalMemory
ПОДРОБНО: Win32_BaseBoard
ПОДРОБНО: Win32_IDEController
ПОДРОБНО: Win32_SCSIController
ПОДРОБНО: Win32_USBController
ПОДРОБНО: Win32_USBHub
ПОДРОБНО: Win32_PointingDevice
ПОДРОБНО: Win32_Keyboard
ПОДРОБНО: Win32_SerialPort
ПОДРОБНО: Win32_ParallelPort
ПОДРОБНО: Win32_ComputerSystemProduct
ПОДРОБНО: Win32_DiskDriveToDiskPartition
ПОДРОБНО: Win32_LogicalDiskToPartition
ПОДРОБНО: Win32_PhysicalMemoryArray
ПОДРОБНО: MSStorageDriver_FailurePredictStatus
ПОДРОБНО: Что-бы получить Exception из Get-WMIObject обязательно применять -ErrorAction stop при вызове.
ПОДРОБНО: Не поддерживается  (-2146233087)
Inserted 266 entries in the database
00:00:21.0719980
19.02.2018 13:39:51
Не поддерживается  (-2146233087): Error in MSStorageDriver_FailurePredictStatus

 .LINK
  https://webnote.satin-pl.com

 .NOTES
  Version:        0.2
  Author:         Pavel Satin
  Email:          plsatin@yandex.ru
  Creation Date:  17.02.2018
  Purpose/Change: Initial script development

#>
Param(
    [Parameter(Mandatory = $false)]
    [string]$ComputerName = "localhost",
    [Parameter(Mandatory = $false)]
    [string]$myFQDN = ""
)


$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3

#$ErrorActionPreference = "SilentlyContinue"
$errorOutput = ""

$connString = "Server=192.168.102.209;Uid=user;Pwd=password;database=inventory;charset=utf8"

Write-Verbose $myFQDN

if ($myFQDN -eq "") {
    if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
        $myFQDN = (Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain
    } else {
        $myFQDN = (Get-WmiObject win32_computersystem).DNSHostName
    }

    $myFQDN = $myFQDN.ToLower()
    Write-Verbose $myFQDN
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
        } catch {
            Write-Host "Could not run MySQL Query" $Error[0]
        } Finally {
            Write-Verbose "Close Connection"
            $connection.Close()
        }

} #Конец функции Invoke-MySQLQuery



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

    $ComputerUUID = Get-ComputerUUID -ComputerName $ComputerName
    Write-Verbose "ComputerUUID: $ComputerUUID"

    Write-Verbose "Обновляем данные системы в tbComputerTarget"

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

    ##Отладочный вывод
    Write-Verbose "Inventory of hardware ..."


    #Выбираем только включенные классы
    $sQLquery = "SELECT ClassID, Name, Namespace, Enabled FROM tbInventoryClass WHERE Enabled = 1"
    $rQLquery = Invoke-MySQLQuery -connectionString $connString -query $sQLquery

    $recordCount = 0
    $deletedClass = 0

    foreach ($row in $rQLquery) {

        [string]$Win32ClassName = $row.Name
        [string]$Win32Namespace = $row.Namespace
        $Win32ClassID = $row.ClassID

        if ($Win32ClassID -eq $deletedClass) {
            # Уже удалили, ничего не делаем

        } else {
            #Удаляем старые записи этого класса
            $sQLqueryDel = "DELETE FROM tbComputerInventory WHERE (ComputerTargetId='$ComputerUUID' AND ClassID = $Win32ClassID)"
            $rQLqueryDel = Invoke-MySQLQuery -connectionString $connString -query $sQLqueryDel
            $deletedClass = $Win32ClassID
        }


        ##Отладочный вывод названия обрабатываемого класса
        Write-Verbose $Win32ClassName

        try {
            $computerClassI = Get-WMIObject -Namespace $Win32Namespace -Class $Win32ClassName -Computer $ComputerName -ErrorAction stop

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


        } catch {
            Write-Verbose "Что-бы получить Exception из Get-WMIObject обязательно применять -ErrorAction stop при вызове."
            $errorstr = $_.Exception.Message + " (" + $_.Exception.HResult + ")"
            $errorOutput += $errorstr + ": Error in $Win32ClassName`n"
            Write-Verbose $errorstr
        }


    }

    Write-Host "Inserted $recordCount entries in the database"

    $watch.Stop() #Остановка таймера
    Write-Host $watch.Elapsed #Время выполнения
    Write-Host (Get-Date)
    Write-Host $errorOutput
    [System.Environment]::Exit($returnStateOK)

} #End if test-connection result
else {
    Write-Host "Host $ComputerName is not available."
    [System.Environment]::Exit($returnStateUnknown)
}
