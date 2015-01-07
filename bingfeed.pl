#!/usr/bin/perl
#Bing shopping feeder CRON 

use lib '/home/httpd/onlinevending2/cgi';
use n2b::dbtools;

use HTML::Strip;
use Net::FTP;
use HTML::Entities;
use SITE;


$d=new dbtools;
$d->dbconnect(&database);
$d->dbquery("select item,storecats.name as storename,subcats.name as subname from catx,storecats,subcats where catx.subcat=subcats.idx and subcats.storecat=storecats.idx");
while ($d->dbnextrow)
{
 $cat{$d->row(item)}=$d->row(storename).' > '.$d->row(subname);
}

@fields=('idx','item','name','longdesc','price','brand','image','path','vendid','recond','retail','mfrname','weight','upc');
@columns=('MPID','Title','Brand','MPN','UPC','SKU','ProductURL','Price','Description','ImageURL','MerchantCategory','ShippingWeight','Condition');
open F,'>'.&getpath.'/web/bingfeed.txt';
$q='select xrefs.*,invs.upc,invs.weight,invs.mfrname,invs.vendid,invs.googlestatus,invs.longdesc,invs.recond,invs.retail,invs.active,invs.price from xrefs,invs '
   .' where xrefs.item=invs.item and invs.active is true and invs.price > 0 and not invs.accessory is true;';

$d->dbquery($q);

while ($d->dbnextrow)
{
 foreach $n (@fields)
 {
  eval('$'.$n.'=$d->row($n);');
 }
 if (length($mfrname)>0)
 {$brand=$mfrname;}
 $tagline=strip($name);
 $tagline=~s/\*//gs;
 $description=strip($longdesc);
 $description=~s/^ +//;
 $description=~s/ +$//;

 $description=~s/\n+/ /gs;
 $description=~s/\r+/ /gs;
 $description=~s/ +/ /gs;
 if ($retail > 0)
 {
  $description ="Name Your Own Price! $description";
 }
 
 $entry=lc $entry;
 $price=sprintf('%8.2f',$price);
 $price=~s/^ +//;
 $p->{Availability}=getstatus($googlestatus);
 $p->{ShippingWeight}=$weight;
 $p->{Title}=strip($tagline);
 $p->{Description}=$description;
 $p->{Brand}=strip($brand); 
 $p->{'MPN'}=strip($vendid);

 $p->{MPID}=$idx;
 if ($recond eq 't')
 {$p->{Condition}='Refurbished'}
 else
  {$p->{Condition}='New'}
 $p->{MerchantCategory}=$cat{$item};
 $p->{ProductURL}='http://'.&siteurl.$path;
 if ($image)
 {
  $p->{ImageURL}='http://'.&siteurl.$image;
 }
 $p->{Price}=$price;
 undef @a;
 foreach $n (@columns)
  {
  	push @a,$p->{$n};
  }
 $buf.=join("\t",@a)."\r\n";
}
$buf=join("\t",@columns)."\r\n"
     .$buf;

print F $buf;

close F;

sub getstatus
{
 my $i=shift;
 my @a=('Available for Order','In Stock','Available for Order','Out of Stock','Preorder');
 return $a[$i];
}

sub strip
{
 my $s=shift;
 my $t;
 my $p=HTML::Strip->new();
 $t= $p->parse($s);
 $t=~s/\&#\d+;//gs;
 return $t;
}



