package contacts;
#Copyright 2007, Net2Business, llc.  All Rights Reserved.

#This is the contact information processing object fron
#the web application framework I designed and built. It
#is reused in dozens of applications.

use vtypedefs;
use Text::Soundex qw(soundex);

$table='contacts';

%vtype=(
# Common Variable Type Defintions
                 idx=>'INDEX',
                 company =>'STRING',
                 salutation=>'STRING',
                 fname=>'NAME',
                 mname=>'NAME',
                 lname=>'NAME',
                 maildrop => 'STRING',
                 workphone=>'PHONE',
                 homephone=>'PHONE',
                 tollfree =>'PHONE',
                 cell=>'PHONE',
                 fax =>'PHONE',
                 position=>'STRING',
                 fsoundex=>'STRING',
                 lsoundex=>'STRING',
                 email=>'EMAIL'
);

@vnames=(keys %vtype);

sub byname
{
 # Fetch a property by name
 my $self=shift;
 my $s=shift;
 my $val=shift;
 
 if (exists $vtype{$s})
 {
   $self->{$s}=dofilter('infilter',$vtype{$s},$val);

   return 1;	
 }
 return undef;	
}

sub loadrec
{
	# not used in this module
 my $self=shift;
}

sub deletestr
{
#method to delete record from the table
 my $buf;
  my $self=shift;
  $buf= "delete from $table where idx=".$self->{idx}.";\n";
  return $buf;
}

sub insertstr
{
 #Insert the record in the table
 my $self=shift;
 my $s;
 my $n;

 setsoundex($self);
 #Pre-compute the soundex table
 
 $s= "insert into $table (".join(',',@vnames).') values (';
 foreach $n (@vnames)
 {
  $s.=dofilter('dbinfilter',$vtype{$n},$self->{$n}).',';
 }
 $s=~s/,$//;

  $s.=");\n";
  return $s;
}

sub updatestr
{
 # Replace record
 my $self=shift;

 return $self->deletestr.$self->insertstr;
}


sub fetch
{
 # Method to fetch record by index
 my $self=shift;
 my $d=shift;
 my $idx=shift;
 my $s;
 my $n;

 $s="select * from $table where idx=$idx;\n";

 $d->dbquery($s);
 if ($d->dbnextrow)
 {
  foreach $n (@vnames)
   {
    $self->{$n}=dofilter('dboutfilter',$vtype{$n},$d->row($n));
   }
 }
}

sub loadform
{
 #load record from the form inputs
 my $self=shift;
 my $q=shift;
 my $ship=shift;
 my $n;
 

foreach $n (@vnames)
 {
  if ($vtype{$n} ne 'INDEX')
  {
   $self->{$n}=dofilter('infilter',$vtype{$n},$q->param("$ship$n"));

  }
 }
}

sub putblank
{
#Clear search and replace tags to output a blank form
 my $self=shift;
 my $ship=shift;
 my $buf=shift;
 my $s;
 my $n;
 my $s2;

 foreach $n (@vnames)
 {
  $s=getinit($vtype{$n});
  $s2='\^'."$ship$n";
  $buf=~s/$s2/$s/gsi;
 }
 return $buf;
}

sub putform
{
 #Format properties and insert into template
 my $self=shift;
 my $ship=shift;
 my $buf=shift;
 my $s;
 my $n;
 my $s2;

 foreach $n (@vnames)
 {
  $s=dofilter('outfilter',$vtype{$n},$self->{$n});
  $s2='\^'."$ship$n";
  $buf=~s/$s2/$s/gsi;
 }
 return $buf;
}

sub setshipto
{
 #Copy bill-to to ship-to
 my $self=shift;
 my $r=shift;
 my $n;

 foreach $n (@vnames)
 {
   if ($n ne 'idx')
   {
    $r->{$n}= $self->{$n};
   }
 }
}

sub mknew
{
 #Create a new database object
 
 my $self=shift;
 my $d=shift;
 my $t;

 $t=$table;
 $t=~s/s$//;

 $d->dbquery("select nextval('".$t."ctr')");
 $d->dbnextrow();
 $self->{idx}=$d->row('nextval');
}

sub maketable
{
 #Create the SQL table for this object
 my $self=shift;
 my $s;
 my $t;
 my $n;

 $t=$table;
 $t=~s/s$//;
 $t=$t."ctr";

 foreach $n (@vnames)
 {
  $s.="$n ".getdbtype($vtype{$n}).',';
 }
 $s=~s/,$//;
 $s="create table $table ($s);\n"
    ."grant all on $table to group web;\n"
    ."create sequence $t start 100;\n"
    ."grant all on $t to group web;\n" ;
 return $s;
}

sub setsoundex
{
 my $self=shift;

 $self->{fsoundex} = soundex($self->{fname});
 $self->{lsoundex} = soundex($self->{lname});

}


sub new {
 my $that  = shift;
 my $class = ref($that) || $that;
 my $self = {

             idx=>0,

        };

        bless $self, $class;
        return $self;
};

1;











