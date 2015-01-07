#!/usr/bin/perl
#A simple command line script to setup the configuration for a new web site.


$d=$ARGV[0];
$dom=$ARGV[1];
$dom=~m/\.(...$)/;
$ext=$1;
$dom=~s/\....$//i;

$block="
<VirtualHost 139.146.143.251>
  Documentroot /home/httpd/$d/web
  HostNameLookups off
  UseCanonicalName off
  Scriptalias /cgi/ /home/httpd/$d/cgi/
  ErrorLog /home/httpd/$d/logs/error_log
  CustomLog /home/httpd/$d/logs/access_log combined
  ErrorDocument 404 /index.html
  ServerName www.$dom.$ext
  ServerAlias $dom.$ext
   <Directory /home/httpd/$d/web/>
    Options +Includes
  </Directory>
</virtualhost>
";

$s='';
if ($ARGV[1])
{

system("mkdir /home/httpd/$d");
system("mkdir /home/httpd/$d/web");
system("mkdir /home/httpd/$d/mail");
system("mkdir /home/httpd/$d/web/stats");
system("mkdir /home/httpd/$d/logs");
system("mkdir /home/httpd/$d/cgi");
system("mkdir /home/httpd/$d/files");
system("mkdir /data/backup/$d");


 open FILE,">/etc/httpd/conf/sites/$d".".conf";
 $block.="ScriptAlias /$dom/cgi/ /home/httpd/$d/cgi/\n";

  print FILE $s.$block;
  print "$d Created\n";
 close FILE;

 open FILE,'>>/home/httpd/weblist.txt';
 print FILE "$d www.$dom.$ext\n";
 print "$d www.$dom.$ext\n";
 close FILE;

}
else
{print "Usage: <directory name> <domain name> Use extension (.com, .org, whatever) on domain\n";}