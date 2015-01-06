package Ithaca;
# The Ithaca receipt printer interface.

$ESC=chr(27);
$ETX=chr(3);

sub Bell
{
 my $self=shift;
 $self->{buf}.=chr(7);
}

sub Cut
{
 my $self=shift;

 $self->{buf}.=$ESC.'v';
}

sub Bold
{
  my $self=shift;

 $self->{buf}.=$ESC.'E';
}

sub SetLeftJustify
{
 my $self=shift;

 $self->{buf}.=$ESC.'a0';
}

sub SetRightJustify
{
 my $self=shift;

 $self->{buf}.=$ESC.'a2';
 }

sub SetCenter
{
 my $self=shift;

 $self->{buf}.=$ESC.'a1';
}

sub Text
{
 my $self=shift;
 my $s=shift;
$self->{buf}.=$s;

}

sub Codabar
{
 my $self=shift;
 my $s=shift;

 $self->{buf}.=$ESC.'b'.chr(8).$s.$ETX;
}

sub BarHeight
{
 my $self=shift;
 my $s=shift;

 $self->{buf}.=$ESC.chr(0x19).'B'.chr($s);
}

sub TextBold
{
 my $self=shift;
 my $s=shift;
$self->{buf}.=$ESC."E$s".$ESC."F";
}

sub DoubleWide
{
 my $self=shift;
 $self->{buf}.=chr(0xE);
}

sub OpenDrawer
{
 my $self=shift;

 $self->{buf}.=$ESC.'x1';
}

sub Lf
{
 my $self=shift;
 my $j=shift;
 my $i;

 for ($i=0;$i<$j;$i++)
 {$self->{buf}.="\r\n"; }
}

sub FineLf
{
 my $self=shift;
 my $j=shift;
 my $i;

$self->{buf}.=$ESC.'J'.chr($j);
}

sub SetQuality
{
 my $self=shift;
 my $j=shift;
 my $i;

$self->{buf}.=$ESC.'I'.chr($j);
}

sub LoadBlob
{
	my $self = shift;
	my $s    = shift;

	$s =~ s/((.)..)/$2/gs;
	$s =~ m/^(.)/;
	$h = $1;
	eval( '$s=~m/([^' . $h . '])/;$l=$1' );

	if ( ord($h) < 128 )
	{
		eval( '$s=~tr/' . $h . $l . '/' . chr(1) . chr(0) . '/' );
	}
	else
	{
		eval( '$s=~tr/' . $h . $l . '/' . chr(0) . chr(1) . '/' );
	}
	$self->{raw} = $s;
}



sub Fetch
{
  my $self=shift;
  my $margin=shift;
  my $i;
  my $s=$self->{raw};
  my $bin;
  my $h;
  my $w;
  my $m;


 for ($i=0;$i<$margin;$i++)
 {
  $m.=chr(0xff);
 }

 for ($i=0;$i<$self->{height};$i++)
{
  $bin=pack('B'.$self->{width},$s);

  $s=substr($s,$self->{width});
  $w=$self->{width}/8 + $margin;
  unless ($self->{width} % 8 == 0)
  {
    $w++;
  } 
 for ($j=length($m.$bin);$j<64;$j++)
 {
  $m2.=chr(0xff);
 }
  $self->{buf}.= $ESC."h".chr(7).chr(65).chr(0).$m.$bin.$m2;
  $m2='';

}
}

sub Fetch2
{
  my $self=shift;
  my $margin=shift;
  my $i;
  my $s=$self->{raw};
  my $bin;
  my $h;
  my $w;
  my $m;


 for ($i=0;$i<$margin;$i++)
 {
  $m.=chr(0xff);
 }
 
 for ($i=0;$i<$self->{height};$i++)
{
  $bin=pack('B'.$self->{width},undercolor($s));  
  $s=substr($s,$self->{width});
  $w=$self->{width}/8 + $margin;
  unless ($self->{width} % 8 == 0)
  {
    $w++;
  } 
 for ($j=length($m.$bin);$j<64;$j++)
 {
  $m2.=chr(0xff);
 }
  $self->{buf}.= $ESC."h".chr(7).chr(65).chr(0).$m.$bin.$m2;
  $m2='';

}
}


sub undercolor
{
 my $s=shift;
 my $s2;
 my $k=0;
 my @a;

 @a=unpack('C*',$s);
 foreach $n (@a)
 {
  if ($k==0)
  {
   $s2.=$n;
   $k=1;
  }
  else
  {
   $s2.=1;
   $k=0;
  }
  
 }
 return $s2;
}

sub PrintFile
{
 my $self=shift;
 my $f=shift;

 open PR, $f;
 print PR $self->{buf};
 close PR;
}

sub new
{
        my $that  = shift;
        my $class = ref($that) || $that;
        my $self={

            width => 0,
            height => 0,
            raw => '',
        buf => ''
        };

       bless $self, $class;
       return $self;
 }
 1;
 

