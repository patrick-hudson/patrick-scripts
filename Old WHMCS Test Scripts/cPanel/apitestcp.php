<?php
require_once("cpanel.php");
$xmlapi = new xmlapi('23.254.42.158');
$xmlapi->password_auth("fkduoite", "XI)AnBaek~5%");
var_dump($xmlapi->listaccts());
?>