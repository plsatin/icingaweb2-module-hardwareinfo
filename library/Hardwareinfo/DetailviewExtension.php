<?php
/* Icinga Web 2 OSMC Module (c) 2017 Icinga Development Team | GPLv2+ */
namespace Icinga\Module\Hardwareinfo;

use Icinga\Module\Monitoring\Hook\DetailviewExtensionHook;
use Icinga\Module\Monitoring\Object\MonitoredObject;
use Icinga\Module\Monitoring\Object\Service;
use Icinga\Module\Monitoring\Object\Host;
use Icinga\Module\Hardwareinfo\Web\Tree\TreeRender;


class DetailviewExtension extends DetailviewExtensionHook
{
    public function getHtmlForObject(MonitoredObject $object)
    {
        if ($object->getName() == "inventory-cycle") {

            $r_AllClass =  "";
            $r_AllClass = TreeRender::renderTree($object->host_name);



// Отображение дерева устройств во вкладке сервиса с именем hardware-inventory. Работает но с этим деревом не удобно работать так как оно обновляется вместе с обновлением вкладки.

            // $hardinfo_out = '
            // <br>
            // <div class="treesearch">
            //     <input type="text" id="jstreehtml_q" name="q" style="width: 8em" class="search" value="" placeholder="Search...">
            // </div>
            // <br>
            // <div id="jstreehtml" class="">
            // '.$r_AllClass
            // .'</div>
            // <script type="text/javascript">
            // $(function () {
            //   $("#jstreehtml").jstree({
            //     "types" : {
            //             "default" : {
            //             "icon" : "jstree-file"
            //         }
            //     },
            //     "plugins" : [ "types", "search" ]
            //   });
            //   var to = false;
            //   $("#jstreehtml_q").keyup(function () {
            //     if(to) { clearTimeout(to); }
            //     to = setTimeout(function () {
            //       var v = $("#jstreehtml_q").val();
            //       $("#jstreehtml").jstree(true).search(v);
            //     }, 250);
            //   });
            // });
            // </script>
            // ';
            

            $hardinfo_out = '<h2>Detail View [hardwareinfo]</h2><br><img src="/icingaweb2/img/hardwareinfo/logo-icinga.png"><br>';

            // $hardinfo_out = '';

            return $hardinfo_out;
        
        }

    }


}
