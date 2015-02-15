<?php
echo '<pre>';
echo "PHP on my Server reports that my IP address is: ";
echo $_SERVER['SERVER_ADDR'];
echo '<br />';
echo '<br />';
echo "External IP address check icanhazip reports that my servers IPv4 address is: ";
$curl = curl_init('http://ipv4.icanhazip.com/');
curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1); 
echo curl_exec($curl);
curl_close($curl); 
echo '<br />';
echo "External IP address check ip4.telize.com reports that my servers IPv4 address is: ";
$curl = curl_init('http://ip4.telize.com/');
curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1); 
echo curl_exec($curl);
curl_close($curl);
echo '<br />';
'</pre>';
?>