<?php
if(!isset($_GET['reload'])){
echo '<!DOCTYPE html>
<head>
<title>Untitled Document</title>

<script src="http://code.jquery.com/jquery-latest.js"></script>
<!-- Latest compiled and minified CSS -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap.min.css">

<!-- Optional theme -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap-theme.min.css">

<!-- Latest compiled and minified JavaScript -->
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/js/bootstrap.min.js"></script>
<script>
    $(document).ready(function(){
    	$("#allthethings").on("click", function(e) {
    		$("#sessiontest").trigger("click");
    		$("#ipcheck").trigger("click");
    		$("#phpinfo").trigger("click");
    	});
		$("#sessiontest").on("click", function(e) {
			e.preventDefault();
			$.post("phpcheck.php?reload=true", {sessioninfo: "true"}, function(response) {
			var obj = jQuery.parseJSON(response);
			var table = "<tr><td>Session Path Writable?</td>";
			
			if(obj.sessionwritable == true){
				var writable = '."\"<td><span class='glyphicon glyphicon-ok' style='color:green'".'></span></td>"
			}
			else{
				var writable = '."\"<td><span class='glyphicon glyphicon-remove' style='color:red'".'></span></td>"
			}
			writable = writable + "<td>Session Path is "+obj.sessionpath+"</td></tr>";
			var active = "<tr><td>Sessions active?</td>";
			if(obj.sessionwritable == true){
				active = active + '."\"<td><span class='glyphicon glyphicon-ok' style='color:green'".'></span></td>"
			}
			else {
				active = active + '."\"<td><span class='glyphicon glyphicon-ok' style='color:red'".'></span></td>"
			}
			active = active + "<td>Session Variable is $_SESSION[\'info\']</td></tr>";
			table = table + writable + active;
			$("#tableresults > tbody:last").append(table);
			console.log(obj.sessionwritable);
			});
		    // the rest of your code ...
		});
		$("#ipcheck").on("click", function(f) {
			f.preventDefault();
			$.post("phpcheck.php?reload=true", {ipinfo: "true"}, function(response) {
			var obj = jQuery.parseJSON(response);
			var table = "<tr><td>Client IP according to PHP</td><td>"+obj.clientip+"</td><td>Header Used: "+obj.ipheader+"</td><tr>";
			table = table + "<tr><td>Client IP when using REMOTE_ADDR</td><td>"+obj.remoteaddr+"</td><td><a href='.'\'http://php.net/manual/en/reserved.variables.server.php\''.'>PHP Docs</a></td></tr>";
			table = table + "<tr><td>Remote IP Check #1</td><td>"+obj.icanhazip+"</td><td>No extra info :(</td></tr>";
			table = table + "<tr><td>Remote IP Check #2</td><td>"+obj.telizei4+"</td><td>No extra info :(</td></tr>";
			table = table + "<tr><td>Remote IPv6 Check</td><td>"+obj.telizei6+"</td><td>No extra info :(</td></tr>";
			$("#tableresults > tbody:last").append(table);
		});
    });
		$("#phpinfo").on("click", function(f) {
			f.preventDefault();
			$.post("phpcheck.php?reload=true", {phpinfo: "true"}, function(response) {
			var obj = jQuery.parseJSON(response);
			var table = "<tr><td>PHP Version</td><td>"+obj.version+"</td><td>Latest <a href='.'\'http://php.net/releases/\''.'>Version:</a></td><tr><td>MySQL Extension Loaded?</td>";
			if(obj.mysql == true){
				var extensions = '."\"<td><span class='glyphicon glyphicon-ok' style='color:green'".'></span></td>"
			}
			else{
				var extensions = '."\"<td><span class='glyphicon glyphicon-remove' style='color:red'".'></span></td>"
			}
			extensions = extensions + "</tr><td>PDO Extension Loaded?</td>"
			if(obj.pdo == true){
				extensions = extensions + '."\"<td><span class='glyphicon glyphicon-ok' style='color:green'".'></span></td>"
			}
			else{
				extensions = extensions + '."\"<td><span class='glyphicon glyphicon-remove' style='color:red'".'></span></td>"
			}
			extensions = extensions + "</tr><td>MySQLi Extension Loaded?</td>"
			if(obj.mysqli == true){
				extensions = extensions + '."\"<td><span class='glyphicon glyphicon-ok' style='color:green'".'></span></td>"
			}
			else{
				extensions = extensions + '."\"<td><span class='glyphicon glyphicon-remove' style='color:red'".'></span></td>"
			}
			extensions = extensions + "</tr><td>PDO_MYSQL Extension Loaded?</td>"
			if(obj.pdomysql == true){
				extensions = extensions + '."\"<td><span class='glyphicon glyphicon-ok' style='color:green'".'></span></td>"
			}
			else{
				extensions = extensions + '."\"<td><span class='glyphicon glyphicon-remove' style='color:red'".'></span></td>"
			}
			extensions = extensions + "</tr><td>IonCube Extension Loaded?</td>"
			if(obj.ioncube == true){
				extensions = extensions + '."\"<td><span class='glyphicon glyphicon-ok' style='color:green'".'></span></td>"
			}
			else{
				extensions = extensions + '."\"<td><span class='glyphicon glyphicon-remove' style='color:red'".'></span></td>"
			}
			table = table + extensions;
			$("#tableresults > tbody:last").append(table);
			console.log(response);
			
		});
    });
});

</script>
</head>

<body>
<div class="page-header">
  <h1>PHP Information Script</h1>
</div>
<div class="col-md-6 col-md-offset-3">
<div class="row">
<div class="panel panel-default">
  <div class="panel-body">
    <div id = "buttons">
    	<a class="btn btn-default" id = "allthethings" role="button">Check ALL the things</a>
    	<a class="btn btn-default" id = "sessiontest" role="button">Check Sessions</a>
    	<a class="btn btn-default" id = "ipcheck"  role="button">Check IP Address Configuration</a>
		<a class="btn btn-default" id = "phpinfo"  role="button">PHP Information</a>
    </div>
</div>
</div>
</div>
<div class="results">
	<table class="table table-striped" id="tableresults">
	<th>Check</th>
	<th>Result</th>
	<th>More Info</th>
	<tbody>
	</tbody>
    </table>
</div>

</div>
</body>
</html>';
}
error_reporting(E_ALL^E_STRICT);
ini_set("display_errors", 1);
$_SESSION["info"] = true;
if(isset($_POST['sessioninfo'])){
	$sessionpath = session_save_path().'/';
	if (is_writable($sessionpath)){
		$writable = true;
	}
	else{
		$writable = false;
	}
	if ($_SESSION["info"] == true){
		$sessionactive = true;
	}
	else {
		$sessionactive = false;
	}
	$sessionarray = array("sessionwritable" => $writable, "sessionactive" => $sessionactive, "sessionpath" => $sessionpath);
	$sessionarray = json_encode($sessionarray);
	echo $sessionarray;
}
if(isset($_POST['ipinfo'])){
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
	$curl = curl_init('http://ipv4.icanhazip.com/');
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1); 
	$icanhazip = curl_exec($curl);
	curl_close($curl); 

	$curl = curl_init('http://ip4.telize.com/');
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1); 
	$telizei4 =  curl_exec($curl);
	curl_close($curl);

	$curl = curl_init('http://ip6.telize.com/');
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
	if ($curl === FALSE) {
		$telizei6 = "error";
	}
	$telizei6 =  curl_exec($curl);
	curl_close($curl);
	$iparray = array("clientip" => $ip, "ipheader" => $type, "remoteaddr" => $_SERVER['REMOTE_ADDR'], "icanhazip" => $icanhazip, "telizei4" => $telizei4, "telizei6" => $telizei6);
	$iparray = json_encode($iparray);
	echo $iparray;
}
if(isset($_POST['phpinfo'])){
	$version = phpversion();
	$extensions = get_loaded_extensions();
	$mysql = (in_array('mysql', $extensions, true) ? true : false);
	$pdo = (in_array('PDO', $extensions, true) ? true : false);
	$mysqli = (in_array('mysqli', $extensions, true) ? true : false);
	$ioncube = (in_array('ionCube Loader', $extensions, true) ? true : false);
	$pdomysql = (in_array('pdo_mysql', $extensions, true) ? true : false);
	$infoarray = array("version" => $version, "mysql" => $mysql, "pdo" => $pdo, "mysqli" => $mysqli, "ioncube" => $ioncube, "pdomysql" => $pdomysql);
	$infoarray = json_encode($infoarray);
	echo $infoarray;
}
?>