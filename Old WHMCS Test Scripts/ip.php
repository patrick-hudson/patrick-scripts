<?php
if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
    $ip = $_SERVER['HTTP_CLIENT_IP'];
    $type = "HTTP CLIENT IP";
} elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
    $type = "HTTP_X_FORWARDED_FOR";
} else {
    $ip = $_SERVER['REMOTE_ADDR'];
    $type = "REMOTE_ADDR";
}
echo "<pre>PHP said my client IP is " . $ip . " I found this using the ".$type. " header\n";
echo "If we were to use REMOTE_ADDR, PHP detects my IP as ".$_SERVER['REMOTE_ADDR'];
echo "</pre>";
?>