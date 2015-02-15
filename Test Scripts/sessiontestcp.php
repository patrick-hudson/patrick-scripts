<?php
error_reporting(E_ALL^E_STRICT);
ini_set("display_errors", 1);

session_start();
$_SESSION["count"]++;
$_SESSION["myuser"] = "test";
$sessionpath = session_save_path().'/';
//print_r($_SESSION);
echo "<b>Session Checks</b>";
echo "<pre>";
echo 'This is your Session ID <pre>'.$_SESSION["myuser"].'<br /> <br />';
echo 'This is your session count <pre>'.$_SESSION["count"].'</pre>The number above should increment by ONE each time you refresh the page';
echo '<br /> <br />Sessions are currently stored in '.$sessionpath;
if (is_writable($sessionpath)){
	echo "<br /> <br />Your session path is writable. Great!\n\n";
}
else{
	echo "<br /> <br /> Your session path is NOT writable. Check the user permissions for the session save path above\n\n";
}
echo "</pre>";
echo "<b>Proxy Check</b>";
echo "<pre>";
if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
    $ip = $_SERVER['HTTP_CLIENT_IP'];
    $type = "HTTP CLIENT IP";
} elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
    $type = "HTTP_X_FORWARDED_FOR (Proxy)";
} else {
    $ip = $_SERVER['REMOTE_ADDR'];
    $type = "REMOTE_ADDR";
}
echo "PHP said my client IP is " . $ip . " using the ".$type. " header\n\n";
echo "If we were to use REMOTE_ADDR, PHP detects my IP as ".$_SERVER['REMOTE_ADDR']."\n\n";
echo "Your IP address shouldn't change when you refresh this page unless you are behind a proxy/cdn/load balancer. If it does, make sure to setup Proxy support in your settings";
echo "</pre>";
?>