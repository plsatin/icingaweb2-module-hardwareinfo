<#
 .SYNOPSIS
  Скрипт для Icinga 2 - Запуск цикла инвентаризации

 .DESCRIPTION


 .PARAMETER ComputerName
  Имя компьютера

 .PARAMETER InventoryType
  Тип инвентаризации. Возможные варианты: All(по умолчанию), Hardware, Software, Updates.

 .OUTPUTS


 .EXAMPLE
.\Invoke-InventoryCycle.ps1 -ComputerName hv7.mkucou.local -InventoryType Hardware


 .LINK
  https://webnote.satin-pl.com

 .NOTES
  Version:        0.1.3
  Author:         Pavel Satin
  Email:          plsatin@yandex.ru
  Creation Date:  26.11.2019
  Purpose/Change: Initial script development
  Creation Date:  26.11.2019 v0.0.2
  Purpose/Change: Add log
  Creation Date:  20.01.2021 v0.1.3
  Purpose/Change: Скорректирован для автаномной работы

#>
Param(
    [Parameter(Mandatory = $true)]
    [string]$ComputerName,
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Hardware", "Software", "Updates")]
    [string]$InventoryType = "All"
)


## Отредактировать перед испольовзанием, а также перед отправкой в порезиторий!
$iniFileContent = @"
# DataBase and API parameters
connString = Server=192.168.102.209;Uid=bduser;Pwd=password;database=inventory;charset=utf8
apiUser = apiuser
apiUserPass = password
apiSiteUrl = 192.168.102.209:5665
"@

$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3
$returnState = $returnStateUnknown

$scriptVersion = "0.2.0"
[int]$PauseScriptSec = 5


# $ErrorActionPreference = "SilentlyContinue"
# [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# $ProgDataFolder = [Environment]::GetFolderPath("CommonApplicationData")
# $icinga2ScriptsPath = "$ProgDataFolder\icinga2\Scripts\icinga2"

$icinga2ScriptsPath = $PSScriptRoot
Import-Module "$icinga2ScriptsPath\icinga-psinventory-module.psm1" #-Verbose

New-Item -ItemType directory -Path "$icinga2ScriptsPath\tmp" -ErrorAction SilentlyContinue
$LogFile = "$icinga2ScriptsPath\tmp\$ComputerName-InventoryCycle.log"
$TaskOutputFile = "$icinga2ScriptsPath\tmp\$ComputerName-IcingaTaskOutput.txt"

Add-LogLine -logFile $LogFile -row "[START][$scriptVersion] Запущен цикл инвентаризации на $ComputerName"

if (!(Test-Path -Path "$icinga2ScriptsPath\icinga-psinventory.ini")) {
    Add-Content -Path "$icinga2ScriptsPath\icinga-psinventory.ini" -Value $iniFileContent -Encoding UTF8
    Add-LogLine -logFile $LogFile -row "Создан ini-файл ($icinga2ScriptsPath\icinga-psinventory.ini)"
}




$result = Test-Connection -ComputerName $ComputerName -Count 2 -Quiet
# $result = $true


## Основное тело скрипта
if ($result) {

    $result_title = "[OK] Inventory cycle started on $ComputerName"
    $returnState = $returnStateOK


    if (Test-Path -Path $TaskOutputFile) {
        Remove-Item $TaskOutputFile -Force
    }


    switch ($InventoryType) { 
        "All" {
            Start-Process powershell -ArgumentList "$icinga2ScriptsPath\Invoke-IcingaInventoryHardware.ps1 -ComputerName $ComputerName -CEnabled 0"

            Add-LogLine -logFile $LogFile -row "Пауза в $PauseScriptSec секунд."
            Start-Sleep -Seconds $PauseScriptSec

            Start-Process powershell -ArgumentList "$icinga2ScriptsPath\Invoke-IcingaInventorySoftware.ps1 -ComputerName $ComputerName"

            Add-LogLine -logFile $LogFile -row "Пауза в $PauseScriptSec секунд."
            Start-Sleep -Seconds $PauseScriptSec

            Start-Process powershell -ArgumentList "$icinga2ScriptsPath\Invoke-IcingaInventoryWindowsUpdates.ps1 -ComputerName $ComputerName"

        }
        "Hardware" {
            Start-Process powershell -ArgumentList "$icinga2ScriptsPath\Invoke-IcingaInventoryHardware.ps1 -ComputerName $ComputerName -CEnabled 0" 

            # Add-LogLine -logFile $LogFile -row "Пауза в $PauseScriptSec секунд."
            # Start-Sleep -Seconds 5
            # Start-Process powershell -ArgumentList "$icinga2ScriptsPath\Invoke-IcingaInventoryHardware.ps1 -CEnabled 2 -ComputerName $ComputerName"
            # Add-LogLine -logFile $LogFile -row "Пауза в $PauseScriptSec секунд."
            # Start-Sleep -Seconds 5
            # Start-Process powershell -ArgumentList "$icinga2ScriptsPath\Invoke-IcingaInventoryHardware.ps1 -CEnabled 3 -ComputerName $ComputerName"

        }
        "Software" {
            Start-Process powershell -ArgumentList "$icinga2ScriptsPath\Invoke-IcingaInventorySoftware.ps1 -ComputerName $ComputerName"

        }
        "Updates" {
            Start-Process powershell -ArgumentList "$icinga2ScriptsPath\Invoke-IcingaInventoryWindowsUpdates.ps1 -ComputerName $ComputerName"

        }
    }






    [string]$fileResultContent = "$result_title `r`n"
    Add-Content -Path $TaskOutputFile -Value $fileResultContent -Encoding UTF8

    Write-Host $result_title
    [System.Environment]::Exit($returnState)

} else {
    Write-Host "[UNKNOWN] Host $ComputerName is not available."
    [System.Environment]::Exit($returnStateUnknown)
}
