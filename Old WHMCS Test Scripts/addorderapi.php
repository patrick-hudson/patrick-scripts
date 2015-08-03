<?php
 $command = "addorder";
 $adminuser = "patrick";
 $values["clientid"] = "4504";
 $values["pid"] = 2;
 $values["domain"] = "whmcs.com";
 $values["billingcycle"] = "monthly";
 $values["paymentmethod"] = "mailin";
 $results = localAPI($command,$values,$adminuser);
?>