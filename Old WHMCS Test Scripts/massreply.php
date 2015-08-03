 <?php
 /* *** WHMCS JSON API Sample Code *** */
 require('init.php');
 for($i=50; $i<510; $i++){
 	$replytime = rand(1, 2);
 	$ranticket = rand(50, 510);
 	for($j=0; $j<$replytime; $j++){
 		$query = select_query('tbladmins', 'firstname, lastname, username', array('id' => $ranadmin));
 		$data = mysql_fetch_array($query);
 		$ranadmin = rand(8, 107);
 		$command = "addticketreply";
	 	$adminuser = $data['username'];
	 	$values["ticketid"] = $ranticket;
	 	$values["adminusername"] = $data['firstname']." ".$data['lastname'];
	 	$values["message"] = "Your ticket has now been received by ".$data['firstname']." ".$data['lastname'];
	 	$results = localAPI($command,$values,$adminuser);
 	}
 }
 ?>