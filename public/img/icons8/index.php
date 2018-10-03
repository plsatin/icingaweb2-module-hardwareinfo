<!DOCTYPE html>
<html lang="ru">
  <head>
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <link href="http://gmpg.org/xfn/11" rel="profile">
    <meta http-equiv="content-type" content="text/html; charset=utf-8">
    <title>Коллекция значков - icons8</title>
    <meta name="robots" content="noindex,nofollow">
    <meta name="description" content="">
    <meta name="theme-color" content="rgb(0, 109, 140)">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=2, minimum-scale=0.5">
    
  </head>
  <body>
    <div style="margin: auto; padding: 40px 8px 40px 8px;">

<?php
//Просмотр всех значков в этой коллекции

$dirname = "./";
$images = glob($dirname."*.png");
$count = 0;

foreach($images as $image) {
    $imgfile = basename($image, ".png");
    echo '<span class="copyable"><img src="'.$image.'" title="'.$image.'" width="32" height="32" hspace="4" vspace="4" alt="'.$imgfile.'" data-clipboard-text="'.$imgfile.'" /></span>';
    $count = $count + 1;
}

echo '<br><hr>';
echo '<p>Всего значков: '.$count.'</p>';

?>

        <blockquote style="background-color: lightgray;">
            <img src="./pin.png" />
            <i>
                При клике на значке, он (объект и название) копируется в буфер обмена.
                <br>
                ...
            </i>
        </blockquote>

    </div>
    <br>
    <small><a href="https://icons8.com" style="color: #888;">© Icons8 LLC</a></small>



    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
    <script>
        //Cross-browser function to select content
        function SelectText(element) {
            var doc = document;
            if (doc.body.createTextRange) {
                var range = document.body.createTextRange();
                range.moveToElementText(element);
                range.select();
            } else if (window.getSelection) {
                var selection = window.getSelection();
                var range = document.createRange();
                range.selectNodeContents(element);
                selection.removeAllRanges();
                selection.addRange(range);
            }
        }

        $(".copyable").click(function (e) {
            //Make the container Div contenteditable
            $(this).attr("contenteditable", true);
            //Select the image
            SelectText($(this).get(0));

            // console.log($(this).attr("alt"));
            // console.log($(this).get(1));
            // console.log(SelectText($(this).get(0)));

            //Execute copy Command
            //Note: This will ONLY work directly inside a click listenner
            document.execCommand('copy');
            //Unselect the content
            window.getSelection().removeAllRanges();
            //Make the container Div uneditable again
            $(this).removeAttr("contenteditable");
            //Success!!
            //alert("image copied!");
        });
    </script>

  </body>
</html>