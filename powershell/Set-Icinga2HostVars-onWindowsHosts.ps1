<#
 .SYNOPSIS
  Скрипт для Icinga 2 - Общая информация о рабочей станции


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


[Console]::OutputEncoding = [System.Text.Encoding]::UTF8


$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3

#$ErrorActionPreference = "SilentlyContinue"

$returnState = $returnStateUnknown


function Send-Icinga2HostVars {
    param(
        [Parameter(Mandatory=$True)]
        [string]    $hostname,
        [string]    $manufacturer,
        [string]    $model,
        [string]    $bios_serial,
        [string]    $board_manufacturer,
        [string]    $board_product,
        [string]    $cpu,
        [string]    $ram,
        [string]    $os,
        [string]    $osarch,
        [string]    $logonuser,
        [string]    $psver,
        [string]    $host_uuid,
        [string]    $dsc_agentid,
        [string]    $targetid
        )


#Доверяем всем сертификатам
add-type -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

#Формируем json
$json = [System.Text.Encoding]::UTF8.GetBytes(@"
{ "attrs": { "vars.manufacturer" : "$manufacturer", "vars.model" : "$model", "vars.bios_serial" : "$bios_serial", "vars.board_manufacturer" : "$board_manufacturer", "vars.board_product" : "$board_product", "vars.cpu" : "$cpu", "vars.ram" : "$ram", "vars.os" : "$os", "vars.os_arch" : "$osarch", "vars.ps_version" : "$psver",  "vars.host_uuid" : "$host_uuid", "vars.dsc_agentid" : "$dsc_agentid", "vars.computer_target_id" : "$targetid"} }
"@)


    $user = "root"
    $pass = "icinga"
    $secpasswd = ConvertTo-SecureString $pass -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($user, $secpasswd)

    $apiurl = "https://192.168.0.209:5665/v1/objects/hosts/" + $hostname

    $headers = @{}
    $headers["Accept"] = "application/json"
    $apireq = Invoke-WebRequest -Credential $credential -Uri $apiurl -Body $json -ContentType "application/json" -Headers $headers -Method Post -UseBasicParsing
    #$apireq.Content | ConvertFrom-Json

} #Конец функции Send-Icinga2HostVars

function Get-ComputerUUID {
    Param(
      [Parameter(
          Mandatory = $true,
          ParameterSetName = '',
          ValueFromPipeline = $true)]
          [string]$ComputerName
    )


    try {

        $ComputerName = $ComputerName.ToLower()
            
        $computerSystem = Get-WmiObject Win32_ComputerSystem -computer $ComputerName -ErrorAction SilentlyContinue -Errorvariable err
        
        if (!$computerSystem) {
            #Запрос не выполнен завершаем!
            Write-Host $err.Message
            $returnState = $returnStateUnknown
            [System.Environment]::Exit($returnState)
        } else {
            $returnState = $returnStateOK
        }

        $ComputerUUID = get-wmiobject Win32_ComputerSystemProduct -computername $ComputerName | Select-Object -ExpandProperty UUID -ErrorAction SilentlyContinue
        $OSSerial = get-wmiobject Win32_OperatingSystem -computername $ComputerName | Select-Object -ExpandProperty SerialNumber -ErrorAction SilentlyContinue

        Write-Verbose "UUID from WMI: $ComputerUUID"

        if ($ComputerUUID -eq "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF") {
            
        } elseif ($ComputerUUID -eq "00000000-0000-0000-0000-000000000000") {

        } elseif ( $ComputerUUID -eq $Null ) {
    
        } else {

        }
    
        $ComputerUUID = $ComputerUUID + "-" + $OSSerial
        Write-Verbose "ComputerUUID: $ComputerUUID"
        
        return $ComputerUUID

    } catch [System.Exception] {
        $errorstr = $_.Exception.toString()
        Write-Verbose $errorstr
    }    
  
} # Конец функции Get-ComputerUUID





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



if ($ComputerName -eq ".") {
    $result = $true
} else {
    $result = Test-Connection -ComputerName $ComputerName -Count 2 -Quiet
}

if ($result) {

    #Замер времени исполнения скрипта
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $watch.Start() #Запуск таймера


    $computerSystem = Get-WmiObject Win32_ComputerSystem -computer $ComputerName -ErrorAction SilentlyContinue -Errorvariable err
    $computerBIOS = Get-WmiObject Win32_BIOS -computer $ComputerName
    $computerBoard = Get-WmiObject Win32_BaseBoard -computer $ComputerName -ErrorAction SilentlyContinue
    $computerOS = Get-WmiObject Win32_OperatingSystem -computer $ComputerName -ErrorAction SilentlyContinue
    $computerCPU = Get-WmiObject Win32_Processor -computer $ComputerName -ErrorAction SilentlyContinue
    #$computerHDD = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID = 'C:'" -computer $ComputerName
    $computerVideo = Get-WmiObject Win32_VideoController -computer $ComputerName -ErrorAction SilentlyContinue
    $computerCSProduct = Get-WMIObject -Class Win32_ComputerSystemProduct -computer $ComputerName -ErrorAction SilentlyContinue


    $ComputerUUID = Get-ComputerUUID -ComputerName $ComputerName
    Write-Verbose "ComputerUUID: $ComputerUUID"


    if (!$computerSystem) {
        #Запрос не выполнен завершаем!
        Write-Host $err.Message
        $returnState = $returnStateUnknown
        [System.Environment]::Exit($returnState)
    } else {
        $returnState = $returnStateOK
    }

    if ( $ComputerName -eq "localhost" ) {
        $computerPSVer = $PSVersionTable.psversion

    } else {
        $computerPSVer = Invoke-Command -Computername $ComputerName -Scriptblock {$PSVersionTable.psversion}
    }


    $ram = "{0:N2}" -f ($computerSystem.TotalPhysicalMemory/1GB) + "GB"
    $os = $computerOS.caption + " SP " + $computerOS.ServicePackMajorVersion
    $osarch = $computerOS.OSArchitecture
    $psver = [string] $computerPSVer.Major + "." + $computerPSVer.Minor

    if ($computerCPU.Name.Count -gt 1) {
        $cpuName =  $computerCPU[0].Name + " (x$($computerCPU.Name.Count))"
    } else {
        $cpuName =  $computerCPU.Name
    }

    if ($ComputerName -eq "localhost") {

        Send-Icinga2HostVars -hostname $myFQDN -manufacturer $computerSystem.Manufacturer -model $computerSystem.Model -bios_serial $computerBIOS.SerialNumber -board_manufacturer $computerBoard.Manufacturer -board_product $computerBoard.Product -cpu $cpuName -ram $ram -os $os -osarch $osarch -logonuser $computerSystem.UserName -psver $psver -host_uuid $computerCSProduct.UUID -targetid $ComputerUUID

    } elseif ($ComputerName -eq ".") {


        Send-Icinga2HostVars -hostname $myFQDN -manufacturer $computerSystem.Manufacturer -model $computerSystem.Model -bios_serial $computerBIOS.SerialNumber -board_manufacturer $computerBoard.Manufacturer -board_product $computerBoard.Product -cpu $cpuName -ram $ram -os $os -osarch $osarch -logonuser $computerSystem.UserName -psver $psver -host_uuid $computerCSProduct.UUID -targetid $ComputerUUID

    } else {

        Send-Icinga2HostVars -hostname $ComputerName -manufacturer $computerSystem.Manufacturer -model $computerSystem.Model -bios_serial $computerBIOS.SerialNumber -board_manufacturer $computerBoard.Manufacturer -board_product $computerBoard.Product -cpu $cpuName -ram $ram -os $os -osarch $osarch -logonuser $computerSystem.UserName -psver $psver -host_uuid $computerCSProduct.UUID -targetid $ComputerUUID

    }



    Write-Host "OK"


    $watch.Stop() #Остановка таймера
    Write-Host $watch.Elapsed #Время выполнения
    Write-Host (Get-Date)

    #Write-Host $output
    [System.Environment]::Exit($returnState)

} #End if test-connection result
else {
    Write-Host "Host $ComputerName is not available."
    [System.Environment]::Exit($returnStateUnknown)
}
