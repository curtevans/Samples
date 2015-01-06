package bccvalidate;
# The BCC geocode interface

use LWP::UserAgent; 
use HTTP::Request; 
use XML::Parser;
use XML::DOM;
use SITE;


sub loader
{
 my $self=shift;
 my $loc=shift;
 
 $self->{Address1}=$loc->{address1};
 $self->{Address2}=$loc->{address2}; 
 $self->{City}=$loc->{city};  
 $self->{State}=$loc->{state};  
 $self->{Zipcode}=$loc->{zip};  
 $self->{Country}=$loc->{country};  
 $self->{UserDefinedId}=$loc->{idx} ; 
 
}

sub checkgeocode
{
 return $self->{result}->{GeoCoded} eq 'Y';
}

sub checkdpv
{
 return ( $self->{result}->{DPV} eq 'Y'
         ||  $self->{result}->{DPV} eq 'S'
         ||  $self->{result}->{DPV} eq 'D'
       );
}

sub store
{
 my $self=shift;
 my $loc=shift;
 
$loc->{address1}=$self->{result}->{Address1};
$loc->{address2}=$self->{result}->{Address2}; 
$loc->{city}=$self->{result}->{City};
$loc->{state}=$self->{result}->{State};
$loc->{zip}=$self->{result}->{Zipcode};
$loc->{country}=$self->{result}->{Country}  ;
 if ($self->{result}->{GeoCoded} eq 'Y'	)
 {
  $loc->{lat}=$self->{result}->{Latitude};
  $loc->{long}=$self->{result}->{Longitude};  
 }	
}

sub storestd
{
 my $self=shift;
 my $std=shift;
 
$std->{address1}=$self->{result}->{Address1};
$std->{address2}=$self->{result}->{Address2}; 
$std->{city}=$self->{result}->{City};
$std->{state}=$self->{result}->{State};
$std->{zip}=$self->{result}->{Zipcode};
$std->{carrierrt}=$self->{result}->{CarrierRoute};
$std->{deliverypt}=$self->{result}->{DeliveryPoint};
$std->{retcode}=$self->{result}->{ReturnCode};
}

sub sendreq
{
 my $self=shift;
 my $doc;
 my $n;
 my $message;
 my $request;
 my $userAgent;
 my $parser;
 my $xml;
 
 open DEBUG,'>>/home/httpd/victorianwse/logs/debug.txt' or die "$!";
 
 $message = '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <EncodeAddress xmlns="http://ws.bccsoftware.com/ZIPFOURce">
 ';
 
 $message.='<LicenseKey>'.&bcckey.'</LicenseKey>';
 foreach $n ('UserDefinedId','Address1','Address2','Address3',
             'SecondaryAddressInfo','Urbanization','City','State',
             'Zipcode','ResellerCustId','Country')
 {
  $message.="<$n>".$self->{$n}."</$n>\n";
 }
$message.='
    </EncodeAddress>
  </soap:Body>
</soap:Envelope>';

print DEBUG ($rctr++)."\n".$message;
#print $message;
$userAgent = LWP::UserAgent->new(); 

$request = HTTP::Request->new(POST => 'https://ws.bccsoftware.com/zipfourcews.asmx');
$request->header(SOAPAction => '"http://ws.bccsoftware.com/ZIPFOURce/EncodeAddress"');
$request->content($message); 
$request->content_type("text/xml; charset=utf-8"); 
$request->content_length(length($message)); 
$response = $userAgent->request($request); 
print DEBUG $response->as_string;
# Extract the XML Response
my $xml = substr($response->as_string, rindex $response->as_string, "<?xml");

# Create an XML Dom and Load XML Response
$parser = XML::DOM::Parser->new();
$doc = $parser->parsestring($xml);
#showxml($xml);

foreach $n ('UserDefinedId','Address1','Address2','Address3',
             'SecondaryAddressInfo','Urbanization','City','State',
             'Zipcode','ResellerCustId','RecordType','ReturnCode',
             'Latitude','Longitude','AreaCode','TimeZone','StatusMessage',
             'CarrierRoute','DVP','GeoCoded','CountryCode','DeliveryPoint')
{
 if (defined $doc->getElementsByTagName($n)->item(0))
 {
  if (defined $doc->getElementsByTagName($n)->item(0)->getFirstChild)
  {
   $self->{result}->{$n}=
           $doc->getElementsByTagName($n)->item(0)->getFirstChild->getNodeValue;
  }
 }
           
}     
close DEBUG;        
}

sub cleanheader
{
 my $s=shift;

return substr($s,index($s,'<?xml'));
}
   
sub showxml
{
 my $s=shift;
 $s=~s/>/>\n/gs;
 print $s;
}   
   
sub new {
 my $that  = shift;
 my $class = ref($that) || $that;
 my $self = {

             LicenseKey=>undef,
             UserDefinedId=>undef,
             Address1=>undef,
             Address2=>undef,
             Address3=>undef,
             SecondaryAddressInfo=>undef,
             Urbanization=>undef,
             City=>undef,
             State=>undef,
             Zipcode=>undef,
             Country=>undef,
             ResellerCustId=>undef,
             result=>undef,
        };

        bless $self, $class;
        return $self;
};
1;             

