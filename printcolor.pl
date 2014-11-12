#!/usr/bin/perl
#Copyright Net2Business, llc 2004.  All Rights Reserved.

#This program creates and prints a sports facility
#player card by combining the customer's
#picture and directly programming a Zebra card printer
#via a custom API I wrote.  This was necessary, as
#no Linux based drivers existed at the time.

use Image::Magick;
use Zebra;
use Text;
use ColorGraphic;
use CGI;
use dbtools;

$Y=0;
$M=1;
$C=2;
$K=3;

$d=new dbtools;
$d->dbconnect(allamerican);

$n=new Zebra;
$q=new CGI;
$player=$q->param(player);
$fname= $q->param(fname);
$lname= $q->param(lname);
$team=$q->param(team);
$expires=$q->param(expires);
$ptype=lc($q->param(ptype));
$capture=$q->param(capture);

#Log the print so we can keep track of cards
putlog($d,'player',$player);

#Printer reset and setup
$n->ClearMediaPath;
$n->ResetEncoder;
$n->SetMagDefault;
$n->SetTrackDensity(1,75);
$n->SetCoercivity('1');

# Write the player number to the magnetic stripe 
$n->WriteMagBuffer(1,'AAIS^'.sprintf('%07d',$player.'^'.&getmonth));
$n->WriteTrackBuffers;

$n->ClearMonoBuffer;
$n->ClearColorBuffers;
$picture=new Image::Magick;
$image=new Image::Magick;

# Get the player card template image
$picture->Read(filename=>'/home/httpd/allam/web/images/cards/'.$ptype.'.jpg');

# If too many teams to list, clip the string
if (length($team)> 20)
{
 $team=substr($team,0,20).'...';
}

# Get the player's picture
$image->Read(filename=>'/home/httpd/allam/web/indpics/P'.$player.'.jpg');


$image->Scale(width=>240,height=>320);
$image->Crop(width=>240,height=>320);

#Make sure we don't exceed mechanical limits
$picture->Scale(width=>int(3.35*300),height=>2.1*300);

#Composite the player picture over the background
$picture->Composite(image=>$image,x=>58,y=>63,compose=>Over);
$picture->Rotate(degrees=> -90);
$height= $picture->Get('height');
$width=$picture->Get('width');

# New Graphic printer object
$g=new ColorGraphic;

$g->SetDims(5,10,$height,$width);

 $t=new Text;
 ;
 $t->SetOrigin('Left',340,365);
 $t->SetString($fname);
 $t->SetFont(1,16);
 $t->SetMode('merge');
 $n->WriteText($t);
 $t->SetOrigin('Left',340,400);
 $t->SetString($lname);
 $t->SetFont(1,12);
 $n->WriteText($t);
 $t->SetFont(1,9);
 $t->SetOrigin('Left',65,463);
 $t->SetString('AAIS #');
 $n->WriteText($t);
 $t->SetOrigin('Left',200,463);
 $t->SetString($player);
 $n->WriteText($t);

 $t->SetOrigin('Left',65,501);
 $t->SetString('Teams:');
$n->WriteText($t);
 $t->SetOrigin('Left',200,501);
 $t->SetString($team);
 $n->WriteText($t);
 $t->SetOrigin('Left',65,531);
 $t->SetString('Expires:');
 $n->WriteText($t);
 $t->SetOrigin('Left',200,531);
 $t->SetString($expires);
 $n->WriteText($t);
#Load card into printer
$n->LoadCard;

#Convert the graphic to printer image
$g->LoadByPixel($picture);
$n->LoadColorGraphic($g);
$n->PrintPanel($Y);
$n->PrintPanel($M);
$n->PrintPanel($C);
$n->PrintMonoPanel;
$n->PrintVarnish;

$n->UnloadCard;

# Send it to the print queue
$n->PrintFile('|lpr -l -h -P Zebra');


print "Content-type: text/html\n\n<html>
        <body onload=\"self.close()\">
        </body>
        <html>";
        
sub putlog
{
 #Keeps track of cards printed to prevent theft.
 my $d=shift;
 my $cardtype=shift;
 my $player=shift;
 
 $player=~s/[^0-9]//gs;
 $player=sprintf('%d',$player);
 my $sql="insert into cardlogs(cardtype,stamp,player)values('$cardtype',now(),$player);";
 $d->dbquery($sql);
}



sub getmonth
{
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);
return sprintf('%02d/%02d',$mon+1,$year-100);
}


