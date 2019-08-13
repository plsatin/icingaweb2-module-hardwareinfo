# Module configuration

## Global configuration

You can edit global configuration settings in Icinga Web 2 in `Configuration -> Modules -> hardwareinfo -> Configuration`.

Setting            | Description
-------------------|-------------------
Database type      | Not implemented yet.
Host               | **Required.** MySQL server host name.
Database           | **Required.** Database name. 
User               | **Required.** Database user name.
Password           | **Required.** Database user password.

## Host configuration

In order for the host to appear in the main module list, it is necessary to set the variable `vars.os_type` in the host configuration.

```
object Host "server1" {
  import "generic-host"
  check_command = "cluster-zone"

  vars.os_type = "Windows Server"

}

```

## Data collection

Read the [How to collect data](doc/04_collect_data.md) section for details.
