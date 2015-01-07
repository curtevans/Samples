//Copyright 2013 Net2Business, llc All Rights Reserved.
// This code captures keystrokes from a scanner and decodes
// an AAMVA formatted driver's license.  Decoded data
// is then inserted into the form.


//Convert 0A to ~ in scanner


window.addEventListener("keypress",getkey,true);

var buf=new String;
buf='';
var a=new Array;
var b=new Array;

var capture=0;
var bufctr=0;
var qctr=0;
var lines=new Array();
var dlrec=new Object;
var qrcode='';

var licenseevent = new CustomEvent(
	"license", 
	{
		detail: {
			message: "licenseDetect",
			time: new Date(),
		},
		bubbles: true,
		cancelable: true
	}
	)
;

var qrcodeevent = new CustomEvent(
	"qrcode", 
	{
		detail: {
			message: "qrcodeDetect",
			time: new Date(),
		},
		bubbles: true,
		cancelable: true
	}
	)
;


function keep(c)
{
 buf+=c;
 bufctr++;
}

function getkey(e)
{
 
  c=String.fromCharCode(e.which);

  if (c == '^')
  {
   keep(c);
   
   capture=1;
   e.preventDefault();
   e.stopPropagation();
   return null;
  }
  
  if (capture == 1)
  { 
    if (c=='!')
   { 
	  capture=0;
      if (buf.substr(0,2)=='^@')
 	  {dldecode();}
      else
 	  {
       if (buf.substr(0,2)=='^~')
	   {qrdecode();}
       else
	   {carddecode();}
      }

	  buf='';

   }
   keep(c);

   e.preventDefault();
   e.stopPropagation();
   return null;
  }  
  return e.which;  
}

function dlparse01()
{
 var a=new Array();
 var i;
 var s;
 a=lines[1].match(/DAA(.+)/).toString().substr(3).split(',');
 dlrec.lname=a[0];
 dlrec.fname=a[1];
 dlrec.mname=a[2];

 for (i=0;i<lines.length;i++)
 {
  switch(lines[i].substr(0,3))
  {
   case 'DAG':dlrec.address1=lines[i].substr(3);break;
   case 'DAI':dlrec.city=lines[i].substr(3);break;      
   case 'DAJ':dlrec.state=lines[i].substr(3);break;           
   case 'DAK':dlrec.zip=lines[i].substr(3);break;   
   case 'DAQ':dlrec.license=lines[i].substr(3);break;   
   case 'DBB':dlrec.dob=lines[i].substr(3);break; 
  }
 }
}

function dlparse02()
{
 var i;
 var s;
 for (i=0;i<lines.length;i++)
 {
  switch(lines[i].substr(0,3))
  {
   case 'DCS':dlrec.lname=lines[i].substr(3);break;
   case 'DCT':dlrec.fname=lines[i].substr(3);break;

   case 'DAG':dlrec.address1=lines[i].substr(3);break;
   case 'DAH':dlrec.address2=lines[i].substr(3);break;
   case 'DAI':dlrec.city=lines[i].substr(3);break;      
   case 'DAJ':dlrec.state=lines[i].substr(3);break;           
   case 'DAK':dlrec.zip=lines[i].substr(3);break;   
   case 'DAQ':dlrec.license=lines[i].substr(3);break;   
   case 'DBB':dlrec.dob=lines[i].substr(3);break; 
  }
 }
}

function dlparse04()
{
 var i;
 var s;
 for (i=0;i<lines.length;i++)
 {
  switch(lines[i].substr(0,3))
  {
   case 'DCS':dlrec.lname=lines[i].substr(3);break;
   case 'DAC':dlrec.fname=lines[i].substr(3);break;
   case 'DAD':dlrec.mname=lines[i].substr(3);break;

   case 'DAG':dlrec.address1=lines[i].substr(3);break;
   case 'DAH':dlrec.address2=lines[i].substr(3);break;
   case 'DAI':dlrec.city=lines[i].substr(3);break;      
   case 'DAJ':dlrec.state=lines[i].substr(3);break;           
   case 'DAK':dlrec.zip=lines[i].substr(3);break;   
   case 'DAQ':dlrec.license=lines[i].substr(3);break;   
   case 'DBB':dlrec.dob=lines[i].substr(3);break; 
  }
 }
}


function loadform()
{
 var a=new Array('fname','lname','address1','city','zip','license');
 var i; 
 var p;

 for (i=0;i<a.length;i++)
 {
   if (document.getElementById(a[i]))
   {
    p=document.getElementById(a[i]);
    eval('p.value=dlrec.'+a[i]+';');
   }
 }

if (document.getElementById('state'))
{
 setstate(dlrec.state);
}
if (document.getElementById('licensestate'))
{
 document.getElementById('licensestate').value=dlrec.state;
}
document.dispatchEvent(licenseevent);
}

function dlparse(version)
{
 if (version=='01')
 (dlparse01())
 if (version=='02'||version=='03')
 (dlparse02())
 if (parseInt(version)>=4)
 (dlparse04())
loadform();

}

function dldecode()
{
 console.log(buf);
 if (buf.indexOf('ANSI')>0)
 {
  lines=buf.split(/~/);
  offset=lines[1].indexOf("ANSI ");
  dlparse(lines[1].substr(offset+11,2));
 }
}

function qrdecode()
{
 var a;
 buf=buf.substr(2);
 buf=buf.substr(0,buf.length-1);
 a=buf.split(';');
 auction=a[0];
 cidx=a[1];
 document.dispatchEvent(qrcodeevent);

}


function setdrop(id,v)
{
 var p=document.getElementById(id);
 var i;
 for (i=0;i<p.options.length;i++)
 {
   if (parseInt(p.options[i].value)==parseInt(v))
   {
    p.selectedIndex=i;
   }
 }
}

function carddecode()
{
var b=new Array();
//  a=buf.split(';');
//  document.info.track1.value=a[0];
//  document.info.track2.value=a[1];

  b=buf.split("^");  
  document.getElementById('cardnumber').value=b[1].replace(/\D/g,'');
  setdrop('expireyear',b[3].substr(0,2));
  setdrop('expiremonth',b[3].substr(2,2));
 // document.info.fname.value=b[1];
//  document.info.cardok.value=1;
 }


function vindecode()
{
  if (buf.match(/\^[A-Za-z0-9]+/))
  {
   buf=buf.replace(/[^A-Za-z0-9]/g,'');
   buf=buf.match(/.................$/);
   document.info.vin.value=buf;
   decodevin(buf);
  }
 }





