<#
 .SYNOPSIS
  Сбор информации об аппаратном обеспечении через WMI.


 .DESCRIPTION


 .PARAMETER ComputerName
  Имя компьютера

 .PARAMETER CEnabled
  Группа классов WMI из базы данных. 0 - Все включенные, 1 - группа 1, 2 - группа 2 и т.д.

 .OUTPUTS


 .EXAMPLE


 .LINK
  https://webnote.satin-pl.com

 .NOTES
  Version:        0.9
  Author:         Pavel Satin
  Email:          plsatin@yandex.ru
  Creation Date:  17.02.2018
  Purpose/Change: Initial script development
  Creation Date:  20.01.2021 v0.1.3
  Purpose/Change: Скорректирован для автаномной работы

#>
Param(
    [Parameter(Mandatory = $true)]
    [string]$ComputerName,
    [Parameter(Mandatory = $false)]
    [string]$CEnabled = "0"

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

# Add-LogLine -logFile $LogFile -row $connString

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

if ($Null -ne $rQLquery.ComputerTargetId) {

    $sQLquery = "UPDATE tbComputerTarget SET Name='$ComputerName', LastReportedInventoryTime='$LastReportedInventoryTime' WHERE ComputerTargetId='$ComputerUUID'"
    $rQLquery = Invoke-MySQLQuery -connectionString $connString -query $sQLquery


} else {

    $sQLquery = "INSERT INTO tbComputerTarget ( ComputerTargetId, Name, LastReportedInventoryTime ) VALUES ( '$ComputerUUID', '$ComputerName', '$LastReportedInventoryTime' )"
    $rQLquery = Invoke-MySQLQuery -connectionString $connString -query $sQLquery

}

##Отладочный вывод
Write-Verbose "Inventory of hardware ..."
Add-LogLine -logFile $LogFile -row "Inventory of hardware ..."

#Выбираем только включенные классы
if ($CEnabled -eq "0") {
    $sQLquery = "SELECT ClassID, Name, Namespace, Enabled FROM tbInventoryClass WHERE Enabled > 0"

} else {
    $sQLquery = "SELECT ClassID, Name, Namespace, Enabled FROM tbInventoryClass WHERE Enabled = $CEnabled"
}
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
    Add-LogLine -logFile $LogFile -row "[C$CEnabled] $Win32ClassName"

    try {
        if ($Win32ClassName -eq "Win32_UserAccount") {
            # Отбираем только локальные учетные записи, иначе можем получить весь домен.
            $computerClassI = Get-WMIObject -Namespace $Win32Namespace -Class $Win32ClassName -ComputerName $ComputerName -ErrorAction stop | Where-Object LocalAccount -eq $True
        } elseif ($Win32ClassName -eq "SoftwareLicensingProduct") {
            $computerClassI = Get-WMIObject -Namespace $Win32Namespace -Class $Win32ClassName -ComputerName $ComputerName -ErrorAction stop | Where-Object PartialProductKey | Select-Object Name, ApplicationId, LicenseStatus, ProductKeyChannel
        } else {
            $computerClassI = Get-WMIObject -Namespace $Win32Namespace -Class $Win32ClassName -ComputerName $ComputerName -ErrorAction stop


        }

        $InstanceId = 0

        if ($computerClassI) {
            foreach ($computerClass in $computerClassI) {
                $InstanceId = $InstanceId + 1

                $sQLqueryProp = "SELECT PropertyID, ClassID, Name FROM tbInventoryProperty WHERE ClassID='$Win32ClassID'"
                $rQLqueryProp = Invoke-MySQLQuery -connectionString $connString -query $sQLqueryProp

                foreach ($rowProp in $rQLqueryProp) {
                    $PropertyID = $rowProp.PropertyID
                    $PropertyName = $rowProp.Name

                    $Value = $computerClass.$PropertyName | Out-String

                    try {
                        if (!($Null -eq $Value) -And ($Value.ToString() -like '*\*')) {
                            Write-Verbose $Value.ToString()
                            $Value = ($Value.ToString()).Replace("\", "\\")
                        } else {

                        }

                    } catch [Exception] {
                        Write-Verbose $_.Exception.ToString()
                    }


                    $sQLDings = "INSERT INTO tbComputerInventory ( ComputerTargetId, ClassID, PropertyID, Value, InstanceId )
                            VALUES ( '$ComputerUUID', '$Win32ClassID', '$PropertyID', '$Value', '$InstanceId' )"

                    Invoke-MySQLQuery -connectionString $connString -query $sQLDings
                    $recordCount ++

                }
            }
        }


    } catch [Exception] {
        Write-Verbose $_.Exception.ToString()
        $errorstr = $_.Exception.Message + " (" + $_.Exception.HResult + ")"
        $errorOutput += $errorstr + ": Error in $Win32ClassName`n"
        Write-Verbose $errorstr
        $errorOutputIcinga += " - [WARNING] " + "$errorstr - Error in $Win32ClassName"
        Add-LogLine -logFile $LogFile -row "$errorstr - Error in $Win32ClassName"
    }


}


$watch.Stop() #Остановка таймера

$IcingaTaskOutput = "[OK] Hardware inventory completed (CEnabled $CEnabled). Inserted $recordCount entries in the database (Execution time: $($watch.Elapsed))."

try {
    Add-Content -Encoding UTF8 $TaskOutputFile "$IcingaTaskOutput $errorOutputIcinga"
} catch {
    Start-Sleep -s 3
    Add-Content -Encoding UTF8 $TaskOutputFile "$IcingaTaskOutput $errorOutputIcinga"
}

Write-Verbose $IcingaTaskOutput
Write-Verbose $watch.Elapsed #Время выполнения
Write-Verbose (Get-Date)
Write-Verbose $errorOutput

Add-LogLine -logFile $LogFile -row $IcingaTaskOutput

# $IcingaTaskHeader = "[OK] Check Hardware and Software inventory `r`n"
$IcingaTaskOutput = Get-Content $TaskOutputFile

Send-Icinga2CheckResults -ComputerName $ComputerName -taskStatus 0 -taskOutput "$IcingaTaskOutput $errorOutputIcinga" -serviceName "inventory-cycle" -apiUser $apiUser -apiUserPass $apiUserPass -apiSiteUrl $apiSiteUrl
