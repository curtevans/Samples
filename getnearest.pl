#!/usr/bin/perl

#This module retrieves and sorts by distance nearby delivery points
#using great a circle calculation to compensate for the earth's curvature. 


use n2b::dbtools;
use CGI;
use Math::Trig;
use SITE;

$q=new CGI;
$d=new dbtools;

$d->dbconnect(&database);

$inzip=$q->param(zip);
$inzip=~s/[0-9]//gs; # US zips only. Strip bad stuff

sub getzips
{
 $sql="select * from zips where zip='$inzip'";

 $d->dbquery($sql);
 if ($d->dbnextrow)
 {
  $olat=$d->row(lat);
  $olong=$d->row(long); 
 }
 else
 {warn "Getnearest: invalid zip code: $inzip";
  exit 0;
 }
 
 #sort the top 100 nearest routes
 
 $sql= "select *,point(zips.lat,zips.long) <-> point ($olat,$olong) as dist "
      ." from zips,routes where routes.zip=zips.zip "
      ." order by dist limit 100; ";
      
 $d->dbquery($sql);
 $count=0;
 while ($d->dbnextrow)
 {
  $zipcodes[$count]->{zip}=$d->row(zip);
  $zipcodes[$count]->{dist}=abs(greatcircle($d->row('lat'),$d->row('long'),
                       $olat,$olong));
  $count++;                        
 }
 &bubble;
 for ($i=0;$i<$count;$i++)
 {
  print $zipcodes[$i]->{zip}."\t".sprintf('%3.2f',$zipcodes[$i]->{dist})."\n";	
 }
}

sub bubble
{
 # Basic bubble sort
	
 my $self=shift;
 my $change=1;
 my $i;
 my $temp;
 

  while ($change)
  {
   $change=0;
   for ($i=0;$i<$count-1;$i++)
   {
    if ($zipcodes[$i]->{dist} > $zipcodes[$i+1]->{dist})
    {
     $temp=$zipcodes[$i];
     $zipcodes[$i]=$zipcodes[$i+1];
     $zipcodes[$i+1]=$temp; 
     $change=1;    
    }
  }
 }
}

sub greatcircle
{
 #Compute actual ground distance
 
 my $lat1=shift;
 my $long1=shift;
 my $lat2=shift;
 my $long2=shift;

	$lat1sin=sin(deg2rad($lat1));
	$lat2sin=sin(deg2rad($lat2));
	$lat1cos=cos(deg2rad($lat1));
	$lat2cos=cos(deg2rad($lat2));
	
	$longcos=cos(deg2rad($long2) - deg2rad($long1));
	$distrads= acos($lat1sin*$lat2sin+$lat1cos*$lat2cos*$longcos);
	$distdeg=($distrads/pi)*180.0;
	$distkm=1.852*60*$distdeg;
	return abs($distkm*0.621371);
}

