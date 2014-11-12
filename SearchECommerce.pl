#!/usr/bin/perl
# The internal ecommerce search engine.
# It accepts an arbitrary number of keywords, 
# a subcategory or a manufacturer as input.
# Keywords are stemmed to allow plural and
# singular words to match.


use n2b::dbtools;
use CGI;
use SITE;
use Lingua::Stem;
use searchlib;
use Data::Dumper;
use entrys;
use cattreecommon;
use HTML::Entities qw(encode_entities_numeric);
use List::Util  qw(min max);
use cleaners;

$q=new CGI;
$d=new dbtools;
$d->dbconnect(&database);

# Get the amazon S3 path
$imagepath=&amazonpath;

#load the output templates
$mobile=$q->param(mobile);
if ($q->param(mobile) eq 'mobile')
{
 $buf=getfile(&getpath."/web/templates/genericmobile.html");
 $entrytemp=getfile(&getpath."/web/templates/entrymobile.html");	
}
else
{
 $buf=getfile(&getpath."/web/templates/generic.html");
 $entrytemp=getfile(&getpath."/web/templates/entry.html");
}
$mfr=$q->param(mfr);

$stem=new Lingua::Stem;
$pagesize=50;
$page=sprintf('%d',$q->param(page));
# Store subcategory
$subcat=cleanint($q->param(subcat));
#Main store category
$storecat=cleanint($q->param(storecat));

$s=lc($q->param(query));
$s=~s/\'//gs; #Eliminate SQl injection
$query=$s;
# Page offset
$offset=cleanint($q->param(offset));

# Lib to create search queries
$lib=new searchlib;

# Build the search qualifier with the keyword set
$qual=$lib->getkeywordstr($stem,$s);

if ($subcat)
{
 # Load the category tree
 $sql="select storecats.name as sname,subcats.name as name,storecat from subcats,storecats where subcats.idx=$subcat and subcats.storecat=storecats.idx";
 $d->dbquery($sql);
 if ($d->dbnextrow)
 {$storecat=$d->row(storecat);
  $storecatname=$d->row(sname);
  $subcatname=$d->row(name);
  $breadcrumb="$storecatname >> $subcatname";
 }
 else
 {
 	$subcatname='Search Results';
 }
}

if ($mfr)
{
 # Search by Manufacturer
 $d->dbquery("select displayname from mfrs where idx=$mfr");
 $d->dbnextrow;
 $storecatname='Shop By Brand - '.$d->row(displayname).' ';
 # Get the result count;
 $sql="select count(mfr) from xrefs where mfr=$mfr";
 $storecat=2000;

}
else
{
# Get the result count
 $sql="select count(idx) from xrefs where $qual";
}

$d->dbquery($sql);
$d->dbnextrow;
$count=$d->row(count);
if ($count < 1 && !$subcat)
{
 # Found nothing
 print "Content-type: text/html\n\n";
 $cattree=maketree($d);
 $buf=~s/\^cattree/$cattree/gs;
 $buf=~s/\^products/<p><\/p><span style="font-size:20pt">Sorry, no products found.<\/span>/gs;
 $buf=~s/\^storecatname/Product/gs;
 $buf=~s/\^subcatname/Search/gs; 
 print globalsr($buf);

 exit 0;
}
else
{
$offset=sprintf('%d',$offset);

$cattree=maketree($d);

if ($subcat)
{ 
 $sql="select distinct entrys.idx as entry,entrys.name,mfrs.displayname,sortorder from catx,entrys,xrefs,mfrs "
      ."where entrys.active is true and xrefs.entry=entrys.idx and xrefs.mfr=mfrs.idx and catx.subcat::int=$subcat and catx.item::int=entrys.idx "
      ."order by sortorder,mfrs.displayname,entrys.name ";

}
elsif ($mfr)
{
 $sql="select distinct entry from xrefs where mfr=$mfr and xrefs.entry=entrys.idx and entrys.active is true offset $offset limit $pagesize";
}
else
{
 $sql="select distinct entry from xrefs where $qual and xrefs.entry=entrys.idx and entrys.active is true offset $offset limit $pagesize";
}

$d->dbquery($sql);
while ($d->dbnextrow)
{
 push @a,$d->row(entry);
}
foreach $n (@a)
{
 $items[$cnt]->{entry}=new entrys;
 $items[$cnt]->{entry}->fetch($d,$n);
 
 $cnt++;
}

#Create the item table grid

$list=&makegrid($entrytemp);
$buf=~s/\^products/$list/s;
$buf=~s/\^title/$storecatname - $subcatname/s;
print "Content-Type: text/html\n\n";
$linkstr=jumpnav($count);
$buf=~s/\^storecatname\b/$storecatname/gs;
$buf=~s/\^subcatname\b/$subcatname/gs;
$buf=~s/\^storecat\b/$storecat/gs;
$buf=~s/\^subcat\b/$subcat/gs;
$buf=~s/\^cattree/$cattree/gs;
#Output the template with global search and replace
print globalsr($buf);
}

sub dollars
{
 my $price=shift;
 my $s;
 $s=sprintf('%8.2f',$price);
 $s=~s/^ +//;
 return ('$'.$s);	
	
}

sub clip
{
 my $s=shift;
 $s=~s/\*.*$//;
 return $s;
}

sub makegrid
{
 # Creates a string containing catalog entry grid.
 # A search and replace is performed on the entry
 # template and appended to the string
 
 my $i;
 my $mastertemplate=shift;
 my $image;
 my $text;
 my $price;
 my $buf;
 my $template;
 
 for ($i=0;$i<$cnt;$i++)	
 {
  $template=$mastertemplate;
  $link='/item'.$mobile.'/P'.sprintf('%05d',$storecat).sprintf('%05d',$subcat).sprintf('%05d',$items[$i]->{entry}->{idx}).'.html';
  $image=$imagepath.'/thumbs/e'.$items[$i]->{entry}->{idx}.'.jpg';
  $name=$items[$i]->{entry}->{name};
  $price=pricerange($items[$i]->{entry}->{items}[0]); 	
  $mfrname=$items[$i]->{entry}->{items}[0]->{block}[0]->{mfrname};
  $teaser=$items[$i]->{entry}->{teaser};
  $detail=$items[$i]->{entry}->{longdesc};
  $detail=~s/"/&quot;/gs;
  $template=~s/\^detail/$detail/gs;  
  $template=~s/\^link/$link/gs;
  $template=~s/\^image/$image/gs;  
  $template=~s/\^name/$name/gs;  
  $template=~s/\^price/$price/gs;  
  $template=~s/\^teaser/$teaser/gs;    
  $template=~s/\^mfrname/$mfrname/gs;    
  $buf.=$template;
 }
 return $buf;
} 



sub jumpnav
{
 # Creates the link for forward and backward search navigation
my $total=shift;
my $jumplink;
my $i;


$pagecount=int($total/$pagesize);
if ($total % $pagesize)
{
 $pagecount++;
}

if ($pagecount > 1)
{
for ($i=0;$i<$pagecount;$i++)
{
 if ($page==$i)
 {
 $jumplink.=" <span class=\"jumpnav\">".($i+1)."</span> "; 	
 }
 else
 {
 $jumplink.=" <a class=\"jumpnav\" href='/cgi/search.pl?"
            ."any=any&store=1&wh=$wh&query=$query&offset=".($i*$pagesize)."&page=$i'> ".($i+1)."</a> ";
 }
}
}

 if ($pagecount>1 && $page < $pagecount-1)
 {
  $jumplink.=" <a class=\"jumpnav\" href='/cgi/search.pl?"
            ."any=any&store=1&wh=$wh&query=$query&offset=".(($page+1)*$pagesize)."&page=".($page+1)."'> Next Page</a> "
 }
 
 if ($pagecount>1 && $page>0)
 {
  $jumplink =" <a class=\"jumpnav\" href='/cgi/search.pl?"
            ."any=any&store=1&wh=$wh&query=$query&offset=".(($i-1)*$pagesize)."&page=".($page-1)."'> Previous Page</a> "
            .$jumplink;
 }
return $jumplink;
}








