#!/usr/bin/perl
# Creates an Asterisk autodialer script for
# outgoing reminder calls

use XML::Simple;
use CGI;
use Crypt::Simple passphrase => 'majordude';
use Data::Dumper;

#Loaded on the target Asterisk web server.
print "Content-type: text/plain\n\n";
$q=new CGI;
unless ($q->param(CMD) eq 'LOAD')
{exit 0;}

$stamp=time;
$path='/var/spool/asterisk/test';
$count=$q->param(count);
$buf=decrypt($q->param(xml));
eval('$x=XMLin($buf)');
print "Count: $count";
&delold;
&delcall;
for ($i=0;$i<$count;$i++)
{
 makefile($x->{dial}[$i],$stamp+$i*60);
}
#system ('mv /var/spool/asterisk/test/*.call /var/spool/asterisk/outgoing');

sub makefile
{
 my $p=shift;
 my $ts=shift;
 my $buf;
 my $f;
 
$phone=$p->{phone};
$year=$p->{year};
$month=sprintf('%02d',$p->{month});
$day=sprintf('%02d',$p->{day});
$address=$p->{address};
$request=$p->{request};
$tries=$p->{tries};
$delay=$p->{delay};
$start=$p->{start};
$start=~s/://;
$charity=$p->{charity};
$subcharity=$p->{subcharity};

if ($subcharity > 0)
{
 $afile='/home/major/sounds/converted/'.$subcharity.'a';
 $bfile='/home/major/sounds/converted/'.$subcharity.'b';
}
else
{
 $afile='/home/major/sounds/converted/'.$charity.'a';
 $bfile='/home/major/sounds/converted/'.$charity.'b';
}
$buf=<<_here;
Channel: SIP/broadvoice/$phone
MaxRetries: 0
Context: pickup
Extension: 10
Priority: 1
Set: afile=$afile
Set: bfile=$bfile
Set: year=$year
Set: month=$month
Set: day=$day
Set: address=at $address
Account: $request
_here

$fname="$path/r".$p->{request}.'.call';
open $f,">$fname";
print $f $buf;
close $f;
#utime ($ts,$ts, $fname);

}



sub delold
{
 my $path="/var/spool/asterisk/test";
 my $src;
 my $name;
 my @a;

 opendir($src,$path);
 while ($name=readdir($src))
 {
  unless ($name=~ m/^\.\.*/)
 { push @a,$name;}
 }
foreach $n (@a)
{
 if ($n=~m/\.call/)
 {
  unlink "$path/$n";
 }
}
}

sub delcall
{
 my $path="/var/spool/asterisk/outgoing";
 my $src;
 my $name;
 my @a;

 opendir($src,$path);
 while ($name=readdir($src))
 {
  unless ($name=~ m/^\.\.*/)
 { push @a,$name;}
 }
foreach $n (@a)
{
 if ($n=~m/\.call/)
 {
  unlink "$path/$n";
 }
}
}
