package amazon;
# The Amazon S3 interface

use Net::Amazon::S3;
use Net::Amazon::S3::Client;
use Net::Amazon::S3::Client::Object;
use SITE;


sub getbucketlist
{
	my $self=shift;
    my $bucketname=shift;	
    my $bucket=$self->{client}->bucket(name=>$bucketname);    

	# list keys in the bucket
  	$response = $bucket->list
      	or die $s3->err . ": " . $s3->errstr;
  		print $response->{bucket}."\n";
  		for my $key (@{ $response->{keys} }) {
        		print "\t".$key->{key}."\n";  
  		}
	
}

sub uploadimage
{
  my $self=shift;
  my $bucketname=shift;
  my $source=shift;
  my $target=shift;
  
  my  $bucket=$self->{client}->bucket(name=>$bucketname);
 
  my $object = $bucket->object( 
                key => $target,
                acl_short    => 'public-read',
                content_type => 'image/jpeg',               
                );

   $object->put_filename($source);
 
}

sub uploadvideo
{
  my $self=shift;
  my $bucketname=shift;
  my $source=shift;
  my $target=shift;
  
  my  $bucket=$self->{client}->bucket(name=>$bucketname);
 
  my $object = $bucket->object( 
                key => $target,
                acl_short    => 'public-read',
                content_type => 'video/mp4',               
                );

   $object->put_filename($source);
 
}

sub new {
 my $that  = shift;
 my $class = ref($that) || $that;
 my $self = {
		s3=>undef,
		client=>undef
        };
        
        ($key,$secret)=&amazonauth;
        $self->{s3}=$s3 = Net::Amazon::S3->new(
    	aws_access_key_id     => $key,
    	aws_secret_access_key => $secret,
    	retry                 => 1,
  		);
  		
        $self->{client} = Net::Amazon::S3::Client->new( s3 => $self->{s3} );        
        bless $self, $class;
        return $self;
};

1;
