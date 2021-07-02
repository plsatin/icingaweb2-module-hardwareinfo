# How to collect data

## Manual collect data

To collect information, it's enough to run the powershell script [Invoke-InventoryCycle.ps1](https://github.com/plsatin/icingaweb2-module-hardwareinfo/blob/master/powershell/Invoke-InventoryCycle.ps1) on the local system.

## Collect data with the icinga2 service on Windows systems

```conf
object CheckCommand "powershell" {
    import "plugin-check-command"
    timeout = 5m

    command = [ "powershell.exe" ]
    arguments = {
        "-command" = {
            skip_key = true
            value = "$ps_command$"
            order = 0
        }
        "-args" = {
            skip_key = true
            value = "$ps_args$"
            order = 1
        }
    }
}

```

```conf
apply Service "inventory-cycle" {
    ; enable_active_checks = false
    max_check_attempts = 2
    check_interval = 420h
    retry_interval = 10m
    enable_perfdata = false

    check_command = "powershell"
    vars.ps_command = "c:\\ProgramData\\icinga2\\Scripts\\icinga2\\Invoke-InventoryCycleps1"
    vars.ps_args = "."
    command_endpoint = host.vars.client_endpoint

    assign where host.name == host.vars.client_endpoint && host.vars.os_family == "Windows"
    ignore where host.vars.os_family == "Linux" || host.vars.os_type == "Linux"
}

```

## Collect data on Linux systems

A script is being developed to collect information about the hardware for Linux hosts. The Python script [check_hard_inventory.py](https://github.com/plsatin/icingaweb2-module-hardwareinfo/blob/master/powershell/linux/check_hard_inventory.py) uses the `python-dmidecode` and `python-mysqldb` modules.

You may need to install the following packages:

```bash
apt-get install python-mysqldb
apt-get install python-dmidecode

```
