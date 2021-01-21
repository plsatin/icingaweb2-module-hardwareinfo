<#
 .SYNOPSIS
  Установка переменных (host.vars) для linux хостов через Icinga2 API

 .DESCRIPTION
  Параметры не предусмотрены, значения устанавливаются на все известные (только) хосты

 .EXAMPLE
  .\Set-Icinga2Vars.ps1
  
 .LINK 
  https://webnote.satin-pl.com

 .NOTES
  Version:        0.1
  Author:         Pavel Satin
  Email:          plsatin@yandex.ru
  Creation Date:  24.01.2018
  Purpose/Change: Initial script development

#>

$ErrorActionPreference = "SilentlyContinue"

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


function Send-ToIcinga {
    param(
        [Parameter(Mandatory=$True)]
        [string] $hostname,
        [string] $manufacturer,
        [string] $model,
        [string] $bios_serial,
        [string] $board_manufacturer,
        [string] $board_product,
        [string] $cpu,
        [string] $ram,
        [string] $os,
        [string] $osarch,
        [string] $logonuser,
        [string] $psver,
        [string] $host_uuid,
        [string] $dsc_agentid,
        [string] $targetid
        )

#Формируем json
$json = [System.Text.Encoding]::UTF8.GetBytes(@"
{ "attrs": { "vars.manufacturer" : "$manufacturer", "vars.model" : "$model", "vars.bios_serial" : "$bios_serial", "vars.board_manufacturer" : "$board_manufacturer", "vars.board_product" : "$board_product", "vars.cpu" : "$cpu", "vars.ram" : "$ram", "vars.os" : "$os", "vars.os_arch" : "$osarch", "vars.ps_version" : "$psver",  "vars.host_uuid" : "$host_uuid", "vars.dsc_agentid" : "$dsc_agentid", "vars.computer_target_id" : "$targetid"} }
"@)

    $user = "root"
    $pass= "icinga"
    $secpasswd = ConvertTo-SecureString $pass -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($user, $secpasswd)

    $apiurl = "https://192.168.0.209:5665/v1/objects/hosts/" + $hostname

    $headers = @{}
    $headers["Accept"] = "application/json"
    $apireq = Invoke-WebRequest -Credential $credential -Uri $apiurl -Body $json -ContentType "application/json" -Headers $headers -Method Post -UseBasicParsing
    #$apireq.Content | ConvertFrom-Json

} #Конец функции отправки


function Get-ServiceFromIcinga {
    param(
        [Parameter(Mandatory=$True)]
        [string]    $hostname,
        [Parameter(Mandatory=$True)]
        [string]    $servicename
        )

    $user = "root"
    $pass= "icinga"
    $secpasswd = ConvertTo-SecureString $pass -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($user, $secpasswd)

    $apiurl = 'https://192.168.0.209:5665/v1/objects/services?service=' + $hostname + '!' + $servicename

    $headers = @{}
    $headers["Accept"] = "application/json"
    $headers["X-HTTP-Method-Override"] = "GET"
    $apireq = Invoke-WebRequest -Credential $credential -Uri $apiurl -Body $json -ContentType "application/json" -Headers $headers -Method Post -UseBasicParsing

    $result = $apireq.Content | ConvertFrom-Json

    return $result

} #Конец функции Get-ServiceFromIcinga







$ComputerName = "icinga-failover.satin-pl.com"
Send-ToIcinga -hostname $ComputerName -manufacturer "OpenVZ" -model "Virtual Machine" -bios_serial "" -board_manufacturer "OpenVZ" -board_product "Virtual Machine" -cpu "Intel(R) Xeon(R) CPU E5-2630 0 @ 2.30GHz" -ram "512M" -os "Ubuntu 14.04.5 LTS" -osarch "x86_64" -logonuser "" -psver "" -host_uuid "" -dsc_agentid "" -targetid ""

$ComputerName = "icinga"
Send-ToIcinga -hostname $ComputerName -manufacturer "Microsoft Corporation" -model "Virtual Machine" -bios_serial "" -board_manufacturer "Microsoft Corporation" -board_product "Virtual Machine" -cpu "Intel(R) Core(TM) i5-3470 CPU @ 3.20GHz" -ram "4GB" -os "Ubuntu 16.04.3 LTS" -osarch "x86_64" -logonuser "" -psver "" -host_uuid "" -dsc_agentid "" -targetid ""

