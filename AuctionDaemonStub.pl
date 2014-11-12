#!/usr/bin/perl
#Auction Server Daemon Version 1.0
#Copyright (c) 2005-2014, Net2Business, llc All Rights Reserved.

#This is a portion of the live auction daemon that handles simultaneous socket connections from the 
#Flash auction clients.  It predates CPAN server modules.
# It effectly handled 1000 simultaneous client connections
# with minimal server load.

use lib '/home/httpd/ksauctions/cgi';
use IO::Socket;
use IO::Select;
use n2b::dbtools;
use xmlbidreq;
use xmlbidresp;
use xmlauthreq;
use xmlauthresp;
use clients;
use POSIX qw(setsid);
use config;
use Time::HiRes qw(time);
use winners;
use bidders;
use buyerform;
use SITE;

$DEBUG=0;
$INFO=1;
$WARN=2;
$CRITICAL=3;

$xmlheader='<?XML version="1.0" encoding="iso-8859-1" ?>';
$auctioncomplete="<bidstatus><done>true</done><reset>1</reset><trig>0</trig><sold>0</sold></bidstatus>\0";

use aucstruct;

# Set the input terminator to a zero byte string
$/ = "\0";

# This is the client intput socket
$lsn = new IO::Socket::INET(Listen => 1,
                                    LocalPort => &auctionport,
                                    Reuse => 1,
                                    Proto => 'tcp' )
           or die ("Couldn't start server: $!");

# This socket connects to the bidder email
# notification service.

$sel = new IO::Select( $lsn );

$talk = new IO::Socket::INET(       Type=> SOCK_STREAM,
                                    PeerPort => &mailport,
                                    PeerAddr => 'localhost',
                                    Proto => 'tcp' )
           or die ("Couldn't attach to mail server: $!");

# Turn off cache
$talk->autoflush(1);

#daemonize
chdir('/');
open STDIN,'/dev/null';
open STDOUT,'>/dev/null';

defined(my $pid = fork)   or serverlog($CRITICAL,"Can't fork: $!");
exit if $pid;
setsid                    or serverlog($CRITICAL,"Can't start a new session: $!");
open STDERR, '>&STDOUT';
umask 0;

&openlog($DEBUG);
$d=new dbtools;
$d->dbconnect(&database);

# Get the bid incremets
&loadbidincs;

serverlog($INFO,"Auction Server ready. ".localtime()."\n");

$bid=10;

$highbid=0;

# Monitor superloop
while (1)
{
 if( @read_ready = $sel->can_read(1) )
 {
  foreach $fh (@read_ready)
   {
   # New socket
     if($fh == $lsn)
     {
      $new = $lsn->accept;
      $sel->add($new);
      $c=new clients;
      $c->{handle}= fileno($new);
      $c->{ptr}= $new;
      $c->{auth}=0;
      push (@client,$c);
      serverlog ($INFO,"Connection from " . fileno($new).' '.$new->peerhost .' - '.localtime(). "\n");
     }
    # New connection
     else
     {
      $input = <$fh>;
      chomp $input;
      if ( $input eq '')
      {disconnect($fh);}
      else
      {
       if ($input eq '!RESETLOG!')
       {
        &rotatelogs;
        serverlog($INFO,'Rotate logs '+localtime());
        disconnect($fh);
       }
       elsif ($input =~m/policy/i)   
       {
       	serverlog ($DEBUG,"Policy Request: $input\n");
       	print $fh &putpolicy;    	
       }     
       elsif ($input =~m/^PING/i)   
       {
       	# Keep alive signal
       	print $fh 'ACK';
        disconnect($fh);      	    	
       }  
       else
       {
        serverlog ($DEBUG,"Input: $input\n");
        process($fh,$input);
       }
      }
     }
 }
}

# Loop through each client looking
# for stuff ready to output
foreach $fh ( @write_ready = $sel->can_write(0) )
{
 foreach $c (@client)
  {
   if (($c->{output} ne '')&& (fileno($fh)==$c->{handle}))
   {
     print $fh $c->{output};
     serverlog($DEBUG,"Output: ".$c->{handle}.': '.$c->{output}."\n");
     $c->{output}='';
   }
  }
}

