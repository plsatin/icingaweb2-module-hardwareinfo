# Module configuration

## Global configuration

You need to go to the Icinga Web 2 resource configuration and create a new database resource

`Configuration -> Application -> Resources -> Create a New Resource`

Setting            | Description
-------------------|-------------------
Resource Type      | **Required.** SQL Database
Resource Name      | **Required.** Resource name
Database Type      | **Required.** Database type - MySQL
Host               | **Required.** MySQL server host name
Port               | MySQL server port number
Database Name      | **Required.** Database name
Userme             | **Required.** Database user name
Password           | **Required.** Database user password
Character Set      | Supported character sets MySQL
Use SSL            | Yes/No

Then save your changes.

Now you can edit module configuration settings in `Configuration -> Modules -> hardwareinfo -> Configuration`

Setting            | Description
-------------------|-------------------
Resource           | **Required.** Resource name

## Host configuration

In order for the host to appear in the main module list, it is necessary to set the variable `vars.os_type` in the host configuration.

```conf
object Host "server1" {
  import "generic-host"
  check_command = "cluster-zone"
  vars.os_type = "Windows Server"
}

```
