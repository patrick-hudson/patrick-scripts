<?php
require("/includes/classes/PHPMailer/class.phpmailer.php");
$mail = new PHPMailer();
$mail->IsSMTP();
$mail->Host = "ellum.net";
$mail->Port = "465";
$mail->Hostname = "ellum.net";
$mail->SMTPSecure = "ssl";
$mail->SMTPAuth = true;
$mail->SMTPDebug = true;
$mail->Username = "support@ellum.net";
$mail->Password = "20T0pG0lf14!";
$mail->Sender = "support@ellum.net";
$mail->From = "support@ellum.net";
$mail->FromName = "Test";
$mail->AddAddress("patrick@whmcs.com","WHMCS");
$mail->Subject = "Test";
$mail->Body = "Test Message";
if(!$mail->Send()) {
	echo "<p>Email Sending Failed - ".$mail->ErrorInfo."</p>";
} else {
    echo "<p>Success</p>";
}
$mail->ClearAddresses();
$mail->SMTPDebug  = 2;
?>