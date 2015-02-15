 <?php
 /* *** WHMCS JSON API Sample Code *** */
 
 $url = "http://whmcs.enthralltech.com/includes/api.php"; # URL to WHMCS API file goes here
 $username = "ent_whmcs"; # Admin username goes here
 $password = "ent_whmcs"; # Admin password goes here
 
 $postfields = array();
 $postfields["username"] = $username;
 $postfields["password"] = md5($password);
 $postfields["action"] = "getactivitylog";
 $postfields["responsetype"] = "json";
 
 $query_string = "";
 foreach ($postfields AS $k=>$v) $query_string .= "$k=".urlencode($v)."&";
 
 $ch = curl_init();
 curl_setopt($ch, CURLOPT_URL, $url);
 curl_setopt($ch, CURLOPT_POST, 1);
 curl_setopt($ch, CURLOPT_TIMEOUT, 30);
 curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
 curl_setopt($ch, CURLOPT_POSTFIELDS, $query_string);
 curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
 curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
 $jsondata = curl_exec($ch);
 if (curl_error($ch)) die("Connection Error: ".curl_errno($ch).' - '.curl_error($ch));
 curl_close($ch);
 
 $arr = json_decode($jsondata); # Decode JSON String
 
 print_r($arr); # Output XML Response as Array
 
 /*
 Debug Output - Uncomment if needed to troubleshoot problems
 echo "<textarea rows=50 cols=100>Request: ".print_r($postfields,true);
 echo "\nResponse: ".htmlentities($jsondata)."\n\nArray: ".print_r($arr,true);
 echo "</textarea>";
 */
 
 ?>