<#
 .SYNOPSIS
  Сбор информации об установленном программном обеспечении через WMI (класс: Win32_Product).


 .DESCRIPTION


 .PARAMETER ComputerName
  Имя компьютера


 .OUTPUTS


 .EXAMPLE


 .LINK
  https://webnote.satin-pl.com

 .NOTES
  Version:        0.8
  Author:         Pavel Satin
  Email:          plsatin@yandex.ru
  Creation Date:  <Date>
  Purpose/Change: Initial script development
  Creation Date:  20.01.2021 v0.1.3
  Purpose/Change: Скорректирован для автаномной работы

#>
Param(
    [Parameter(Mandatory = $true)]
    [string]$ComputerName
)


# $ErrorActionPreference = "SilentlyContinue"
# [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$icinga2ScriptsPath = $PSScriptRoot
Import-Module "$icinga2ScriptsPath\icinga-psinventory-module.psm1" #-Verbose

New-Item -ItemType directory -Path "$icinga2ScriptsPath\tmp" -ErrorAction SilentlyContinue
$LogFile = "$icinga2ScriptsPath\tmp\$ComputerName-InventoryCycle.log"
$TaskOutputFile = "$icinga2ScriptsPath\tmp\$ComputerName-IcingaTaskOutput.txt"
 
## Get DataBase and API parameters from ini-file
Get-Content "$icinga2ScriptsPath\icinga-psinventory.ini" | Where-Object {$_.length -gt 0} | Where-Object {!$_.StartsWith("#")} | ForEach-Object {
    $var = $_.Split('=',2).Trim()
    New-Variable -Scope Script -Name $var[0] -Value $var[1]
}

$errorOutput = ""
$errorOutputIcinga = ""



#Замер времени исполнения скрипта
$watch = [System.Diagnostics.Stopwatch]::StartNew()
$watch.Start() #Запуск таймера



$ComputerUUID = Get-ComputerUUID -ComputerName $ComputerName
Write-Verbose "ComputerUUID: $ComputerUUID"
Add-LogLine -logFile $LogFile -row "ComputerUUID: $ComputerUUID"


Write-Verbose "Обновляем данные системы в tbComputerTarget"
Add-LogLine -logFile $LogFile -row "Обновляем данные системы в tbComputerTarget"

$sQLquery = "SELECT Name, ComputerTargetId FROM tbComputerTarget WHERE ComputerTargetId='$ComputerUUID'"
$rQLquery = Invoke-MySQLQuery -connectionString $connString -query $sQLquery
[string]$LastReportedInventoryTime = get-date -Format "yyyy-MM-dd HH:mm:ss"


$sQLqueryS = "SELECT ClassID, Name, Namespace, Enabled FROM tbInventoryClass WHERE Name = 'Win32_Product'"
$rQLqueryS = Invoke-MySQLQuery -connectionString $connString -query $sQLqueryS

foreach ($row in $rQLqueryS) {
    $ClassID = $row.ClassID
    [string]$Win32ClassName = $row.Name
}



if ($Null -ne $rQLquery.ComputerTargetId) {

    $sQLquery = "UPDATE tbComputerTarget SET Name='$ComputerName', LastReportedSoftInventoryTime='$LastReportedInventoryTime' WHERE ComputerTargetId='$ComputerUUID'"
    $rQLquery = Invoke-MySQLQuery -connectionString $connString -query $sQLquery


    $sQLqueryDel = "DELETE FROM tbComputerSoftInventory WHERE ComputerTargetId='$ComputerUUID'"
    $rQLqueryDel = Invoke-MySQLQuery -connectionString $connString -query $sQLqueryDel

} else {

    $sQLquery = "INSERT INTO tbComputerTarget ( ComputerTargetId, Name, LastReportedSoftInventoryTime ) VALUES ( '$ComputerUUID', '$ComputerName', '$LastReportedInventoryTime' )"
    $rQLquery = Invoke-MySQLQuery -connectionString $connString -query $sQLquery

}
##########################################################################


##Отладочный вывод
Write-Verbose "Inventory of Software ..."
Add-LogLine -logFile $LogFile -row "Inventory of Software ..."

$recordCount = 0

$computerClassI = Get-WMIObject -Class $Win32ClassName -ComputerName $ComputerName | Sort-Object InstallDate –Descending
$InstanceId = 0
#$SnapshotId = 0

$sQLqueryProp = "SELECT PropertyID, ClassID, Name FROM tbInventoryProperty WHERE ClassID='$ClassID'"
$rQLqueryProp = Invoke-MySQLQuery -connectionString $connString -query $sQLqueryProp

foreach ($computerClass in $computerClassI) {

    $InstanceId = $InstanceId + 1

    foreach ($rowProp in $rQLqueryProp) {
        if ($rowProp.Name -eq "Name") {
            $PropertyName = $rowProp.PropertyID
            $Value = $computerClass.Name
            $Value = $Value -replace "[']",""

            $sQLDings = "INSERT INTO tbComputerSoftInventory ( ComputerTargetId, PropertyID, Value, InstanceId )
                VALUES ( '$ComputerUUID', '$PropertyName', '$Value', '$InstanceId' )"

            Invoke-MySQLQuery -connectionString $connString -query $sQLDings
            $recordCount ++

        } elseif ($rowProp.Name -eq "Version") {
            $PropertyName = $rowProp.PropertyID
            $Value = $computerClass.Version

            $sQLDings = "INSERT INTO tbComputerSoftInventory ( ComputerTargetId, PropertyID, Value, InstanceId )
                VALUES ( '$ComputerUUID', '$PropertyName', '$Value', '$InstanceId' )"

            Invoke-MySQLQuery -connectionString $connString -query $sQLDings
            $recordCount ++

        } elseif ($rowProp.Name -eq "Vendor") {
            $PropertyName = $rowProp.PropertyID
            $Value = $computerClass.Vendor

            $sQLDings = "INSERT INTO tbComputerSoftInventory ( ComputerTargetId, PropertyID, Value, InstanceId )
                VALUES ( '$ComputerUUID', '$PropertyName', '$Value', '$InstanceId' )"

            Invoke-MySQLQuery -connectionString $connString -query $sQLDings
            $recordCount ++

        } elseif ($rowProp.Name -eq "InstallDate") {
            $PropertyName = $rowProp.PropertyID
            $Value = $computerClass.InstallDate

            $sQLDings = "INSERT INTO tbComputerSoftInventory ( ComputerTargetId, PropertyID, Value, InstanceId )
                VALUES ( '$ComputerUUID', '$PropertyName', '$Value', '$InstanceId' )"

            Invoke-MySQLQuery -connectionString $connString -query $sQLDings
            $recordCount ++

        } elseif ($rowProp.Name -eq "IdentifyingNumber") {
            $PropertyName = $rowProp.PropertyID
            $Value = $computerClass.IdentifyingNumber

            $sQLDings = "INSERT INTO tbComputerSoftInventory ( ComputerTargetId, PropertyID, Value, InstanceId )
                VALUES ( '$ComputerUUID', '$PropertyName', '$Value', '$InstanceId' )"

            Invoke-MySQLQuery -connectionString $connString -query $sQLDings
            $recordCount ++

        }

    }

}


$watch.Stop() #Остановка таймера

if ($recordCount -eq 0) {
    $IcingaTaskOutput = "[WARNING] Software inventory completed, but inserted $recordCount entries in the database (Execution time: $($watch.Elapsed))."
} else {
    $IcingaTaskOutput = "[OK] Software inventory completed. Inserted $recordCount entries in the database (Execution time: $($watch.Elapsed))."
}

try {
    Add-Content -Encoding UTF8 $TaskOutputFile $IcingaTaskOutput
} catch {
    Start-Sleep -s 3
    Add-Content -Encoding UTF8 $TaskOutputFile $IcingaTaskOutput
}

Write-Verbose $IcingaTaskOutput
Write-Verbose $watch.Elapsed #Время выполнения
Write-Verbose (Get-Date)
Write-Verbose $errorOutput

Add-LogLine -logFile $LogFile -row $IcingaTaskOutput

$IcingaTaskOutput = Get-Content $TaskOutputFile

if ($recordCount -eq 0) {
    Send-Icinga2CheckResults -ComputerName $ComputerName -taskStatus 1 -taskOutput "$IcingaTaskOutput $errorOutputIcinga" -serviceName "inventory-cycle" -apiUser $apiUser -apiUserPass $apiUserPass -apiSiteUrl $apiSiteUrl
} else {
    Send-Icinga2CheckResults -ComputerName $ComputerName -taskStatus 0 -taskOutput "$IcingaTaskOutput $errorOutputIcinga" -serviceName "inventory-cycle" -apiUser $apiUser -apiUserPass $apiUserPass -apiSiteUrl $apiSiteUrl
}
