package xactblock;
#  set of methods for recording
# trasactions in the Point of Sale journal
use xacts;
use payments;
use authorizecpshort;

%types=(purchase => 7,
        salestax => 10,
        cash =>1,
        credit=>12,
        check=>2,
        cashrefund=>5,
        creditrefund=>15,
        void=>6,
        issuecredit=>16,
   	vendorincome=>11
        );

sub addxact
{
 my $self=shift;
 $self->{x}[$self->{xcount}]=new xacts;
 $self->{x}[$self->{xcount}]->{idx}=$self->{idx};
 $self->{x}[$self->{xcount}]->{ind}=$self->{ind};
 $self->{x}[$self->{xcount}]->{team}=$self->{team};
 $self->{x}[$self->{xcount}]->{posted}=0;
 $self->{x}[$self->{xcount}]->{register}=$self->{register};
 $self->{x}[$self->{xcount}]->{eid}=$self->{eid}; 
 $self->{current}=$self->{x}[$self->{xcount}];
 $self->{xcount}++;
 return $self->{current};
}

sub mknew
{
 my $self=shift;
 my $d=shift;
 my $register=shift;
 my $ind=shift;
 my $team=shift;
 my $eid=shift;

 $d->dbquery("select nextval('xactctr')");
 $d->dbnextrow;
 $self->{idx}=$d->row('nextval');
 $self->{register}=$register;
 $self->{ind}=$ind;
 $self->{team}=$team;
 $self->{eid}=$eid; 
}

sub addtxincinv
{
 my $self=shift;
 my $qty=shift;
 my $inv=shift;
 my $name=shift;
 my $amount=shift;
 my $taxrate=shift;
 my $p;
 my $r;

addxact($self);
$p=$self->{current};
$p->{xtype}=$types{'purchase'};
$p->{inv}=$inv;
$p->{qty}=$qty;
$p->{name}=$name;
$r=sprintf('%8.2f',$amount/(1.0+$taxrate));


$p->{amount}=sprintf('%8.2f',$amount/(1.0+$taxrate));

$p->{tax}=sprintf('%8.2f',$r*$taxrate); 
warn("Amount:$amount \$p amount:".$p->{amount}.' $p tax:'.$p->{tax}."\n");
if ( ($p->{amount}+$p->{tax} > $amount) || ($p->{amount}+$p->{tax} < $amount))
{
 $p->{amount}+=($amount-($p->{amount}+$p->{tax}));
 $p->{amount}=sprintf('%8.2f',$p->{amount});
 warn('Subtract: '.($amount-($p->{amount}+$p->{tax}))."\n");
}

$p->{taxrate}=sprintf('%8.7f',$taxrate); 
$self->{salestax}+=sprintf('%8.2f',$r*$taxrate);
}

sub addinv
{
 my $self=shift;
 my $qty=shift;
 my $inv=shift;
 my $name=shift;
 my $amount=shift;
 my $taxrate=shift;
 my $p;
 my $r;

addxact($self);
$p=$self->{current};
$p->{xtype}=$types{'purchase'};
$p->{inv}=$inv;
$p->{qty}=$qty;
$p->{name}=$name;
$p->{amount}=$amount;
$p->{tax}=sprintf('%8.2f',$amount*$taxrate);
$p->{taxrate}=sprintf('%8.7f',$taxrate);
$self->{salestax}+=sprintf('%8.2f',$amount*$taxrate);
}

sub addnotaxinv
{
 my $self=shift;
 my $qty=shift;
 my $inv=shift;
 my $name=shift;
 my $amount=shift;
 my $taxrate=shift;
 my $p;
 my $r;

addxact($self);
$p=$self->{current};
$p->{xtype}=$types{'purchase'};
$p->{inv}=$inv;
$p->{qty}=$qty;
$p->{name}=$name;
$p->{amount}=$amount;
$p->{tax}=0;
$p->{taxrate}=0;

}

sub addtaxrec
{
 my $self=shift;
 my $p;
 addxact($self);
 $p=$self->{current};
 $p->{name}='Sales Tax';
 $p->{xtype}=$types{'salestax'};
 $p->{amount}=$self->{salestax};
}

sub addvendorpmt
{
 my $self=shift;
 my $vendor=shift;
 my $register=shift;
 my $amount=shift;
 my $eid=shift;
 my $x;

 $x=addxact($self);
 $x->{register}=$register;
 $x->{xtype}=11;
 $x->{amount}=$amount;
 $x->{name}=uc ($vendor).' Income';
 $x->{eid}=$eid;
}

sub addvendorrefund
{
 my $self=shift;
 my $vendor=shift;
 my $amount=shift;
 my $register=shift;
 my $eid=shift;
 my $x;

 $x=addxact($self);
 $x->{register}=$register;
 $x->{xtype}=17;
 $x->{amount}=$amount;
 $x->{name}=uc ($vendor).' Refund';
 $x->{eid}=$eid; 
}

sub addvendorreimb
{
 my $self=shift;
 my $vendor=shift;
 my $amount=shift;
 my $register=shift;
 my $eid=shift; 
 my $x;

 $x=addxact($self);
 $x->{register}=$register;
 $x->{xtype}=20;
 $x->{amount}=$amount;
 $x->{name}=uc ($vendor).' Reimb';
  $x->{eid}=$eid;
}


sub addcashpmt
{
 my $self=shift;
 my $amount=shift;
 my $x;

 $x= addxact($self);
 $x->{name}='Cash Payment';
 $x->{xtype}=$types{'cash'};
 $x->{amount}=$amount;
}

sub addrefund
{
 my $self=shift;
 my $amount=shift;
 my $x;

 $x= addxact($self);
 $x->{name}='Refund';
 $x->{xtype}=$types{'creditrefund'};
 $x->{amount}=$amount;
 $x->{payment}=$amount;
}

sub addcashrefund
{
 my $self=shift;
 my $amount=shift;
 my $x;

 $x= addxact($self);
 $x->{name}='Refund';
 $x->{xtype}=$types{'cashrefund'};
 $x->{amount}=$amount;
 $x->{payment}=$amount;
}

sub addissuecredit
{
 my $self=shift;
 my $amount=shift;
 my $x;

 $x= addxact($self);
 $x->{name}='Credit';
 $x->{xtype}=$types{'issuecredit'};
 $x->{amount}=$amount;
 $x->{payment}=$amount;
}


sub addnamedcredit
{
 my $self=shift;
 my $amount=shift;
 my $name=shift;
 my $eid=shift;
 my $x;

 $x= addxact($self);
 $x->{name}=$name;
 $x->{xtype}=$types{'issuecredit'};
 $x->{amount}=$amount;
 $x->{payment}=$amount;
 $x->{eid}=$eid;
}

sub addvoid
{
 my $self=shift;
 my $amount=shift;
 my $x;

 $x= addxact($self);
 $x->{name}='Void';
 $x->{xtype}=$types{'void'};
 $x->{amount}=$amount;
 $x->{payment}=$amount;
}

sub addcardpmt
{
 my $self=shift;
 my $amount=shift;
 my $payment=shift;
 my $x;

 $x= addxact($self);
 $x->{name}='Card Payment';
 $x->{xtype}=$types{'credit'};
 $x->{amount}=$amount;
 $x->{payment}=$payment;
}

sub addcheckpmt
{
 my $self=shift;
 my $amount=shift;
 my $payment=shift;
 my $x;

 $x= addxact($self);
 $x->{name}='Check Payment';
 $x->{xtype}=$types{'check'};
 $x->{amount}=$amount;
 $x->{payment}=$payment;
}

sub insertstr
{
 my $self=shift;
 my $i;
 my $buf;

 for ($i=0;$i<$self->{xcount};$i++)
 {
  $buf.=$self->{x}[$i]->insertstr;
 }
 return $buf;
}

sub new
{
        my $that  = shift;
        my $class = ref($that) || $that;
        my $self={

         idx => undef,
         register => 1,
         ind => 0,
         x=>[],
         xcount=>0,
         salestax =>0,
         current=>0,
         eid=>0,
         team=>0
          };

       bless $self, $class;
       return $self;
 }


1;


