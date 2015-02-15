<?php
if(fsockopen("whois.registry.net.za",43))
{
echo "I can see port 43";
}
else
{
echo "I cannot see port 43";
}
?>