#!/usr/bin/perl
print "Content-type: text/html\n\n";
 
$title='Perl Mail demo';
$to='patrick.hudson@rackspace.com';
$from= 'noreply@appraisalscope.com';
$subject='YOUR SUBJECT';
 
open(MAIL, "|/usr/sbin/sendmail -t");
 
## Mail Header
print MAIL "To: $to\n";
print MAIL "From: $from\n";
print MAIL "Subject: $subject\n\n";
## Mail Body
print MAIL "This is a test message \n";
 
close(MAIL);
 