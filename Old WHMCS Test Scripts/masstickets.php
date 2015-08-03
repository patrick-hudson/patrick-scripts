 <?php
 /* *** WHMCS JSON API Sample Code *** */
 require('init.php');
 for($i=4; $i<4504; $i++){
 	$query = select_query('tblclients', 'firstname, lastname', array('id' => $i));
 	$data = mysql_fetch_array($query);
 	$command = "openticket";
	$adminuser = "patrick";
	$values["clientid"] = $i;
	$values["deptid"] = "3";
	$values["subject"] = "Test Ticket From ".$data['firstname']." ".$data['lastname'];
	$values["message"] = "This is a sample ticket opened by the API as a client";
	$values["priority"] = "Low";
	$results = localAPI($command,$values,$adminuser);
 }
 ?>