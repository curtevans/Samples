package fedex8;

# Copyright 2007-2013, Net2Business, llc.  All Rights Reserved.
# This module provides the interface for the Ajax Shipping module
# to talk to fedex and fedex freight.
 
use LWP::UserAgent;
use XML::Simple;

use SITE;
use Date::Calc qw(Add_Delta_Days);

sub build
{
	my $self = shift;
	my ( $key, $password, $account, $meter, $freightaccount ) = &fedexcred;
	$self->{account} = $account;
	if ($freightaccount)
	{
		$self->{freightaccount} = $freightaccount;
	}
	else
	{
		$self->{freightaccount} = $account;
	}

	$self->{buf} = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" 
xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" 
xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" 
xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"http://fedex.com/ws/rate/v13\">
	<SOAP-ENV:Body>
<RateRequest xmlns=\"http://fedex.com/ws/rate/v13\">
			<WebAuthenticationDetail>
				<UserCredential>
					<Key>$key</Key>
					<Password>$password</Password>
				</UserCredential>
			</WebAuthenticationDetail>
			<ClientDetail>
				<AccountNumber>$account</AccountNumber>
				<MeterNumber>$meter</MeterNumber>
			</ClientDetail>
			<TransactionDetail>
				<CustomerTransactionId>Net2Business, llc</CustomerTransactionId>
			</TransactionDetail>
			<Version>
				<ServiceId>crs</ServiceId>
				<Major>13</Major>
				<Intermediate>0</Intermediate>
				<Minor>0</Minor>
			</Version>		
";

	if ( $self->{isfreight} ) { freightpack($self); }
	else { packagelist($self); }

	$self->{buf} .= '</RequestedShipment>
		</RateRequest>
	</SOAP-ENV:Body>
</SOAP-ENV:Envelope>';
}

sub packagelist
{
	my $self = shift;
	my $i;

	$timestamp = $self->{timestamp};
	$self->{buf} .= "<RequestedShipment>	
                <ShipTimestamp>$timestamp</ShipTimestamp>				
			    <DropoffType>REGULAR_PICKUP</DropoffType>		
                <PackagingType>YOUR_PACKAGING</PackagingType>";
	$self->{buf} .= $self->{origin};
	$self->{buf} .= $self->{destination};
	$self->{buf} .= '<RateRequestTypes>LIST</RateRequestTypes>';
	$self->{buf} .= '<PackageCount>' . $self->{pkgctr} . '</PackageCount>';
	for ( $i = 0 ; $i < $self->{pkgctr} ; $i++ )
	{
		$self->{buf} .=
		    '<RequestedPackageLineItems>'
		  . '<GroupPackageCount>1</GroupPackageCount>'
		  . '<Weight><Units>LB</Units><Value>'
		  . $self->{pkg}[$i]->{weight}
		  . '</Value></Weight>'
		  . $self->{pkg}[$i]->{dims}
		  . '</RequestedPackageLineItems>';

	}

}

sub setspecials
{

	my $self = shift;
	my $s;
	
	if ($self->{callbefore})
	{
		$s.=
		    '<SpecialServiceTypes>'
		  . 'CALL_BEFORE_DELIVERY'
		  . '</SpecialServiceTypes>';
        $self->{specialtext}.='-Call Ahead';
	}
	if ($self->{insidedelivery})
	{
		$s.=
		    '<SpecialServiceTypes>'
		  . 'INSIDE_DELIVERY'
		  . '</SpecialServiceTypes>';
	        $self->{specialtext}.='-Inside Delivery';	
	}
	if ($self->{liftgate})
	{
		$s.=
		    '<SpecialServiceTypes>'
		  . 'LIFTGATE_DELIVERY'
		  . '</SpecialServiceTypes>';
        $self->{specialtext}.='-Liftgate';
	}

	if ( length $s )
	{
		return "<SpecialServicesRequested>$s</SpecialServicesRequested>";
	}
	return "";
}

sub loadpackage
{
	my $self         = shift;
	my $weight       = shift;
	my $l            = shift;
	my $w            = shift;
	my $h            = shift;
	my $freightclass = shift;

	$self->{pkg}[ $self->{pkgctr} ]->{weight} = sprintf( '%6.2f', $weight );
	$self->{pkg}[ $self->{pkgctr} ]->{dims} = setdims( $l, $w, $h );
	$self->{pkg}[ $self->{pkgctr} ]->{freightclass} =
	  freightclassform($freightclass);

	$self->{pkgctr}++;

}

sub setlocation
{
	my $self = shift;
	my $p1   = shift;
	my $p2   = shift;

	my $residential = shift;
	my $rescode;

	unless ( $p1->{country} ) { $p1->{country} = 'US'; }
	unless ( $p2->{country} ) { $p2->{country} = 'US'; }

	$self->{origin} = '<Shipper>'
	  . '<Address>'
	  . '<StreetLines>'
	  . $p1->{address1}
	  . '</StreetLines>'
	  . '<City>'
	  . $p1->{city}
	  . '</City>'
	  . '<StateOrProvinceCode>'
	  . $p1->{state}
	  . '</StateOrProvinceCode>'
	  . '<PostalCode>'
	  . $p1->{zip}
	  . '</PostalCode>'
	  . '<CountryCode>'
	  . $p1->{country}
	  . '</CountryCode>'
	  . '</Address>'
	  . '</Shipper>';
	if ($residential) 
	{ $rescode = '<Residential>true</Residential>'; 
	  $self->{specialtext}.='-Residential';
	}
	else { $rescode = '<Residential>false</Residential>'; }
	$self->{destination} =
	    '<Recipient>'
	  . '<Address>'
	  . '<StreetLines>'
	  . $p2->{address1}
	  . '</StreetLines>'
	  . '<City>'
	  . $p2->{city}
	  . '</City>'
	  . '<StateOrProvinceCode>'
	  . $p2->{state}
	  . '</StateOrProvinceCode>'
	  . '<PostalCode>'
	  . $p2->{zip}
	  . '</PostalCode>'
	  . '<CountryCode>'
	  . $p2->{country}
	  . '</CountryCode>'
	  . $rescode
	  . '</Address>'
	  . '</Recipient>'

	  ;
}

sub shipbilling
{
	my $self    = shift;
	my $account = $self->{freightaccount};
	my ( $addr, $state, $zip ) = &shiporigin;
	my ( $street, $city ) = split( /, /, $addr );
	$city = 'Shawnee Mission';
	my $s = "
       <AlternateBilling>
        <AccountNumber>$account</AccountNumber>
        <Address>
          <StreetLines>$street</StreetLines>
          <City>$city</City>
          <StateOrProvinceCode>$state</StateOrProvinceCode>
          <PostalCode>$zip</PostalCode>
          <CountryCode>US</CountryCode>
        </Address>
      </AlternateBilling>
";
	return $s;
}

sub freightpack
{
	my $self = shift;
	my $i;
	my $s;

	$self->{buf} .=
	    "<ReturnTransitAndCommit>true</ReturnTransitAndCommit>"
	  . "<RequestedShipment>"
	  . $self->{origin}
	  . $self->{destination}
	  . "<ShippingChargesPayment>
      <PaymentType>SENDER</PaymentType>
      <Payor>
        <ResponsibleParty>
          <AccountNumber>"
	  . $self->{freightaccount} . "</AccountNumber>
        </ResponsibleParty>
      </Payor>
     </ShippingChargesPayment>"
	  . setspecials($self)
	  . "<FreightShipmentDetail>"
	  . shipbilling($self)
	  . "<Role>SHIPPER</Role>";
	for ( $i = 0 ; $i < $self->{pkgctr} ; $i++ )
	{

		if ( $i == 0 && length( $self->{pkg}[0]->{dims} ) > 0 )
		{
			$s = $self->{pkg}[0]->{dims};
			$s =~ s/\<Dimensions\>//s;
			$s =~ s/\<\/Dimensions\>//s;
			$self->{buf} .=
			  "<ShipmentDimensions>" . $s . "</ShipmentDimensions>";
		}
		$self->{buf} .=
		    '<LineItems>'
		  . '<FreightClass>'
		  . $self->{pkg}[$i]->{freightclass}
		  . '</FreightClass>'
		  . '<Packaging>PALLET</Packaging>'
		  . '<Weight>'
		  . '<Units>LB</Units>'
		  . '<Value>'
		  . $self->{pkg}[$i]->{weight}
		  . '</Value>'
		  . '</Weight>'
		  . $self->{pkg}[$i]->{dims}
		  . '</LineItems>';
	}
	$self->{buf} .= "</FreightShipmentDetail>
                 <RateRequestTypes>ACCOUNT</RateRequestTypes>
                 ";
}

sub freightclassform
{
	my $s = shift;
	$s =~ s/^ +//;
	$s =~ s/ +$//;
	$s =~ s/ +/ /g;
	my @a = split( /\./, $s );
	my @b;
	if ( scalar @a > 1 )
	{
		return 'CLASS_' . sprintf( '%03d_%1d', $a[0], $a[1] );
	}
	  else
	  {
		return 'CLASS_' . sprintf( '%03d', $a[0] );
	  }
	
}

sub setdims
{
	my $l = shift;
	my $w = shift;
	my $h = shift;

	my $s = '';

	if ( ( $l + $h + $w ) > 0 )
	{
		$l = sprintf( '%d', $l + 0.5 );
		$w = sprintf( '%d', $w + 0.5 );
		$h = sprintf( '%d', $h + 0.5 );
		$s =
		    "<Dimensions>"
		  . "<Length>$l</Length>"
		  . "<Width>$h</Width>"
		  . "<Height>$w</Height>"
		  . "<Units>IN</Units>"
		  . "</Dimensions>";
	}

	return $s;
}

sub process
{
	my $self = shift;

	$self->{result} =
	  eval { XMLin( clearv3( $self->{response} ), ForceArray => 1 ) };
	decoder($self);
	return $self->{response};

}

sub clearv3
{
	my $s = shift;
	my $v;
	$v = 'xmlns="http://fedex.com/ws/rate/v13"';
	$s =~ s/$v//gsi;
	return ($s);
}

sub decoder
{
	my $self = shift;
	my $i;
	my $p;
    my $f;
    
	$i = 0;

		$p = $self->{result}->{'SOAP-ENV:Body'}[0]->{'RateReply'}[0];
		while ( exists $p->{'RateReplyDetails'}[$i] )
		{
			loader( $self, $p->{'RateReplyDetails'}[$i], $i );
			$i++;
		}
# 	open $f, ">>/home/httpd/onlinevending2/logs/shipping.log";
}

sub loader
{
	my $self = shift;
	my $p    = shift;

	if ( $self->{isfreight} )
	{
		$self->{options}[ $self->{optionctr} ]->{service} =
		  $p->{ServiceType}[0];
		$self->{options}[ $self->{optionctr} ]->{amount} =
		  $p->{RatedShipmentDetails}[0]{ShipmentRateDetail}[0]{TotalNetCharge}[0]{Amount}[0];
	}
	else
	{
		$self->{options}[ $self->{optionctr} ]->{service} =
		  $p->{ServiceType}[0];
		$self->{options}[ $self->{optionctr} ]->{amount} =
		  $p->{RatedShipmentDetails}[0]{ShipmentRateDetail}[0]{TotalNetCharge}[0]{Amount}[0];
	}

	  $self->{optionctr}++;

}

sub getoption
{
	my $self = shift;
	my $i    = shift;
	my $s;
	my $code;
	my $name;
	my $s2;

	$code = $self->{options}[$i]->{service};
	$name = setupper( $self->{options}[$i]->{service} );
	unless ( $name =~ m/fedex/i )
	{
		$name = "Fedex $name";
	}
	return ( $code, $name, $self->{options}[$i]->{amount} );
}

sub putlist
{
	my $self = shift;
	my $qty  = shift;
	my $i;
	my $s;
	my $code;
	my $name;
	my $s2;
	my $r;

	$s = "<count>" . $self->{optionctr} . "</count>";
	for ( $i = 0 ; $i < $self->{optionctr} ; $i++ )
	{
		$code = $self->{options}[$i]->{service};
		$name = setupper( $self->{options}[$i]->{service} );
		unless ( $name =~ m/fedex/i )
		{
			$name = "Fedex $name";
		}
		$r = $self->{options}[$i]->{amount};
		if ($qty) { $r *= $qty }
		$s .=
		    '<option>' . '<code>' . $code
		  . '</code>'
		  . '<name>'
		  . $name
		  . '</name>'
		  . '<amount>'
		  . $self->{options}[$i]->{amount}
		  . "</amount>"
		  . '</option>';
	}
	return '<fedex>' . $s . '</fedex>';
}

sub calcshipdate
{
	my $self = shift;
	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
	  localtime(time);
	my $day;
	my %nextmonday = ( 0 => 1, 1 => 2, 2 => 6, 3 => 5, 4 => 4, 5 => 3, 6 => 2 );

	my ( $year, $mon, $day ) =
	  Add_Delta_Days( $year + 1900, $mon + 1, $mday, $nextmonday{$wday} );
	$self->{shipdate} = sprintf( '%04d-%02d-%02d', $year, $mon, $day );
	$self->{timestamp} = $self->{shipdate} . 'T09:00:00';
	return $self->{shipdate};
}

sub putoptions
{
	my $self = shift;
	my $i;
	my $s;
	my $code;
	my $name;
	my $s2;

	my $selected = " selected";

	sortoptions($self);
	for ( $i = 0 ; $i < $self->{optionctr} ; $i++ )
	{
		$code = $self->{options}[$i]->{service};
		$name = setupper( $self->{options}[$i]->{service} );
		unless ( $name =~ m/fedex/i )
		{
			$name = "Fedex $name";
		}
		$s .=
		    '<option value="' . $code . '::' . $name . '::'
		  . $self->{options}[$i]->{amount} .'::'.$self->{specialtext}. '"'
		  . $selected . '>'
		  . "$name - "
		  . $self->{options}[$i]->{amount}
		  . "</option>\n";
		$selected = '';
	}

	return $s;
}

sub sortoptions
{
	my $self = shift;
	my $code;
	my $amount;
	my $change = 1;
	my $i      = 0;

	while ( $change == 1 )
	{
		$change = 0;
		for ( $i = 0 ; $i < $self->{optionctr} - 1 ; $i++ )
		{
			if ( $self->{options}[$i]->{amount} >
				$self->{options}[ $i + 1 ]->{amount} )
			{
				$change = 1;
				$amount = $self->{options}[$i]->{amount};
				$code   = $self->{options}[$i]->{service};
				$self->{options}[$i]->{amount} =
				  $self->{options}[ $i + 1 ]->{amount};
				$self->{options}[$i]->{service} =
				  $self->{options}[ $i + 1 ]->{service};
				$self->{options}[ $i + 1 ]->{amount}  = $amount;
				$self->{options}[ $i + 1 ]->{service} = $code;
			}

		}

	}
}

sub setupper
{
	my $s = shift;
	$s =~ s/_/ /g;
	my @a = split( / /, $s );
	my $i;

	for ( $i = 0 ; $i < scalar @a ; $i++ )
	{
		$a[$i] = ucfirst( lc $a[$i] );
	}
	return join( ' ', @a );
}

sub xmit
{
	my $self = shift;
	my $ua;
	my $req;
	my $res;
	my $p;
	my $x;
	my $f;
	$ua = new LWP::UserAgent;
	$ua->agent( "Net2Business/0.1 " . $ua->agent );

	$req = new HTTP::Request POST => 'https://ws.fedex.com:443/web-services';

	#POST => 'https://wsbeta.fedex.com:443/web-services';
	$req->content_type('text/xml; charset=utf-8');
	$req->header( 'SOAPAction' => 'rateAvailableServices' );
	$self->{buf} =~ s/\n//gs;
	$self->{buf} =~ s/\t/ /gs;
	$self->{buf} =~ s/ +/ /gs;
	$self->{buf} =~ s/> </></gs;
	$req->content( $self->{buf} );

	$res                = $ua->request($req);
	$self->{is_success} = $res->is_success;
	$self->{response}   = $res->content;
#	open $f, ">>/home/httpd/onlinevending2/logs/shipping.log";
#	print $f "\n\nFEDEX REQUEST:" . $self->{buf} . "\n\n" . $self->{response};
	$self->{ok} = 1;

}

sub new
{
	my $that  = shift;
	my $class = ref($that) || $that;
	my $self  = {
		buf => ''

	};
	bless $self, $class;
	calcshipdate($self);
	return $self;
}

1;
