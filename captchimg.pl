#!/usr/bin/perl
#Creates a CAPCHA PNG image

$|=1;

binmode STDOUT;

use Image::Magick;
use Digest::MD5 qw(md5_hex);
use CGI;
use SITE;

$q=new CGI;
$session=$q->param(session);

$string=md5_hex(substr($session,1,1).substr($session,3,2).substr($session,6,1).substr($session,1,1));
$string=substr($string,0,6);

$img=Image::Magick->new;
$img->Read(&getpath.'/web/images/captchaback.png'); 

$offset=20;
$count=0;

foreach $c (split(//,$string))
{ 
 $img->Annotate(font=>'Times-Roman',pointsize=>24,fill=>'rgb(12,140,198)',text=>$c,  
                x=>10 + $count * 28,y=>int(20 + rand()*5),
                rotate => int(rand()*30) - 15
                ); 
 $count++;
}

print "Content-type: image/png\n\n"; 
$img->Write('png:-');

