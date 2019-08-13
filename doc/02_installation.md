# Installation

## Requirements

  * [Icinga Web 2](https://www.icinga.com/products/icinga-web-2/) (>= 2.4.1)
  * [MySQL](https://www.mysql.com) (>=5.5)
  * [PHP](https://www.php.net)


## Installation the Hardwareinfo module

Create a MySQL database using the script: [inventory.sql](https://github.com/plsatin/icingaweb2-module-hardwareinfo/blob/master/sql/inventory.sql)

Extract this module to your Icinga Web 2 modules directory as `hardwareinfo` directory.

Git clone:

```bash
cd /usr/share/icingaweb2/modules
git clone https://github.com/plsatin/icingaweb2-module-hardwareinfo.git hardwareinfo
```

Enable the module in the Icinga Web 2 frontend in `Configuration -> Modules -> hardwareinfo -> enable`.
You can also enable the module by using the `icingacli` command:

```bash
icingacli module enable hardwareinfo
```
