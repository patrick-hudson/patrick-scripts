<?php

    $whmcsurl = "https://www.whmcs.com/index.php";
    $postfields = array("curltest"=>"1");

    $ip = gethostbyname('licensing28.whmcs.com');

    echo "<font style=\"font-size:18px;\">Testing Connection to '$whmcsurl'...<br />URL resolves to $ip<br /><br />";

    if ($ip!="184.94.192.3" && $ip!="208.74.120.227") echo "<font style=\"color:#cc0000;\">Error: The IP whmcs.com is resolving to the wrong IP. Someone on your server is trying to bypass licensing. You'll need your host to investigate and fix.</font><br /><br />";

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $whmcsurl);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $postfields);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    $data = curl_exec($ch);

	if (curl_error($ch)) {
		echo "Curl Error: ".curl_error($ch)."<br /><br />";
	} elseif (!$data) {
        echo "Empty Data Response - Please check CURL Installation<br /><br />";
    }

	curl_close($ch);
	
	echo "Connection Response (this should be the HTML from $whmcsurl when working correctly):<br /><br /><textarea rows=\"20\" cols=\"120\">$data</textarea>";

?>