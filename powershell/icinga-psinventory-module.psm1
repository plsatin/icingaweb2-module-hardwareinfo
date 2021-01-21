<#
 .SYNOPSIS
  Модуль вложенных функций для скриптов инвентаризации хостов

 .DESCRIPTION


 .LINK
  https://webnote.satin-pl.com

 .NOTES
  Version:        0.2
  Author:         Pavel Satin
  Email:          plsatin@yandex.ru
  Creation Date:  20.01.2021
  Purpose/Change: Initial script development

#>




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

        # # Обязательно заменить в промышленной среде!!!
        # $icinga2ScriptsPath = "C:\ProgramData\icinga2\Scripts\icinga2"
        $icinga2ScriptsPath = $PSScriptRoot

        $mySQLDataDLL = "$icinga2ScriptsPath\bin\MySQL.Data.dll"
        [void][system.reflection.Assembly]::LoadFrom($mySQLDataDLL)
        #[void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
        $connection = New-Object MySql.Data.MySqlClient.MySqlConnection
        $connection.ConnectionString = $ConnectionString
        Write-Verbose "Open Database Connection"
        $connection.Open()


        # # Set timeout on MySql
        # $cmdTimeOut = New-Object MySql.Data.MySqlClient.MySqlCommand("set net_write_timeout=99999; set net_read_timeout=99999", $connection) 
        # $cmdTimeOut.ExecuteNonQuery()


        # Run MySQL Querys
        Write-Verbose "Run MySQL Querys"
        $command = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $connection)
        $dataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($command)
        $dataSet = New-Object System.Data.DataSet
        $recordCount = $dataAdapter.Fill($dataSet, "data")
        $dataSet.Tables["data"] # | Format-Table

    } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Could not run MySQL Query" $ErrorMessage
    } finally {
        Write-Verbose "Close Connection"
        $connection.Close()
    }

  } #Конец функции Invoke-MySQLQuery

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
            # $ComputerUUID = $(Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Cryptography -Name MachineGuid).MachineGuid
            # $ComputerUUID = $ComputerUUID.ToUpper()

        } elseif ($ComputerUUID -eq "00000000-0000-0000-0000-000000000000") {
            # $ComputerUUID = $(Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Cryptography -Name MachineGuid).MachineGuid
            # $ComputerUUID = $ComputerUUID.ToUpper()

        } elseif ($ComputerUUID -eq "03000200-0400-0500-0006-000700080009") {
            if ($OSSerial -eq "00425-00000-00002-AA147") {

                # $someString = $env:Computername
                # $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
                # $utf8 = new-object -TypeName System.Text.UTF8Encoding
                # $ComputerUUID = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($someString)))

                $ComputerUUID = $(Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Cryptography -Name MachineGuid).MachineGuid
                $ComputerUUID = $ComputerUUID.ToUpper()

            }

        } elseif ( $Null -eq $ComputerUUID ) {

            # $someString = $env:Computername
            # $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
            # $utf8 = new-object -TypeName System.Text.UTF8Encoding
            # $ComputerUUID = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($someString)))

            $ComputerUUID = $(Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Cryptography -Name MachineGuid).MachineGuid
            $ComputerUUID = $ComputerUUID.ToUpper()

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

function Add-LogLine([String]$logFile = $(Throw 'LogLine:$logFile unspecified'),
        [String]$row = $(Throw 'LogLine:$row unspecified')) {
    $logDateTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Encoding UTF8 $logFile ($logDateTime + " - " + $row)
} #Конец функции LogLine

function Send-Icinga2CheckResults {
    Param(
        [Parameter(Position=0,Mandatory = $true)]
        [string]$ComputerName,
        [Parameter(Position=1,Mandatory = $true)]
        [string]$taskStatus,
        [Parameter(Position=2,Mandatory = $true)]
        [string]$taskOutput,
        [Parameter(Position=3,Mandatory = $false)]
        [string]$serviceName = "support-ticket",
        [Parameter(Position=4,Mandatory = $true)]
        [string]$apiUser,
        [Parameter(Position=5,Mandatory = $true)]
        [string]$apiUserPass,
        [Parameter(Position=6,Mandatory = $true)]
        [string]$apiSiteUrl
    )

    # $ErrorActionPreference = "SilentlyContinue"
    # [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    $taskOutput = $taskOutput
    $taskOutput = $taskOutput -replace "[\\]", "/"
    $taskOutput = $taskOutput -replace '"', "'"

    Write-Verbose $taskOutput
    
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
    
    # В версии Icinga2 2.11 используется TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $secpasswd = ConvertTo-SecureString $apiUserPass -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($apiUser, $secpasswd)
    
    $json = [System.Text.Encoding]::UTF8.GetBytes(@"
{ "exit_status": $taskStatus, "plugin_output": "$taskOutput", "check_source": "$ComputerName" }
"@)

    $apiurl = "https://$apiSiteUrl/v1/actions/process-check-result?service=$ComputerName!$serviceName"
    
    $headers = @{}
    $headers["Accept"] = "application/json"



    $retryCount = 0
    $completed = $False
    $response = $Null
    # $result = $Null
    $SecondsDelay = 2
    $Retries = 17


    while (-not $completed) {
        try {
    
            $response = Invoke-WebRequest -Credential $credential -Uri $apiurl -Body $json -ContentType "application/json" -Headers $headers -Method Post -UseBasicParsing
            if ($response.StatusCode -ne 200) {
                throw "Expecting reponse code 200, was: $($response.StatusCode)"
            }
            $completed = $True
        } catch {
            if ($retryCount -ge $Retries) {
                Write-Verbose "Request to $url failed the maximum number of $retryCount times."
                $completed = $True
                throw
            } else {
                Write-Verbose "Request to $url failed. Retrying in $SecondsDelay seconds."
                Start-Sleep $SecondsDelay
                $retryCount++
            }
        }
    }


} # End function Send-Icinga2CheckResults







Export-ModuleMember -Function Invoke-MySQLQuery
Export-ModuleMember -Function Get-ComputerUUID
Export-ModuleMember -Function Add-LogLine
Export-ModuleMember -Function Send-Icinga2CheckResults
