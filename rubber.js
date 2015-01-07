//An HTML5 rubber band editor

var dragnow;
var borderwidth=2;
var st=false;

function down()
{
 dragnow=true;
 startx=tempx;
 starty=tempy;
}

function up(st)
{
 dragnow=false;
 update();
}

function move(e)
{
 var left;
 var top;
 var ofx;
 var ofy;
 
 left=parseInt(id.style.left);
 top=parseInt(id.style.top);
 tempx=e.clientX;
 tempy=e.clientY;

 //document.getElementById('coords').innerHTML=tempx+' '+tempy+' '+dragnow+' '+st;
 if (dragnow)
 {
  ofx=e.clientX - startx;
  ofy=e.clientY - starty;
  if (st)
  {
   stretch(e);
  }
  else
  {
	if (    (left < e.clientX) 
         && (top < e.clientY)
         && (left+ ofx > cp.x) 
         && (top+ ofy > cp.y)
         && (left+ofx+parseInt(id.style.width) < cp.x + parseInt(maincanvas.width)-borderwidth)
         && (top+ofy+parseInt(id.style.height) < cp.y + parseInt(maincanvas.height)-borderwidth)

       )
	 {	
	  id.style.left=(left+ ofx)+'px';
	  id.style.top=(top+ ofy)+'px';
     }
   }
  startx=e.clientX;
  starty=e.clientY;
  if (  e.clientX > cp.x+parseInt(maincanvas.width) 
     || e.clientY > cp.y+parseInt(maincanvas.height)
     || e.clientY < cp.y  
     || e.clientX < cp.x
    )
  { dragnow=false;
    stretchoff();
  }
 }
}

function stopdrag()
{
 dragnow=false;
}

function getaspect(e)
{
 var x;
 var y;
 
 x=e.clientX-parseInt(id.style.top);
 y=e.clientY-parseInt(id.style.left); 
 return (x/y == aspect)
 
}
function sethandle()
{
 gh.style.left=(parseInt(id.style.width)-8)+'px';
 gh.style.top=(parseInt(id.style.height)-8)+'px';
}

function stretch(e)
{

  id.style.width = (e.clientX-parseInt(id.style.left))+'px'; 
  id.style.height = (e.clientY-parseInt(id.style.top))+'px'; 
	sethandle();
}

function stretchoff()
{
 st=false;
 if (parseInt(id.style.height) > parseInt(maincanvas.height))
 {
  id.style.height=maincanvas.height-parseInt(id.style.top);
 }
 id.style.width=(Math.floor(parseInt(id.style.height)*aspect))+'px';
 aspect=parseInt(id.style.width)/parseInt(id.style.height);

 sethandle();
}

function store()
{
 var s;
 var sharp;
 var autolevel;
 sharp='';
}

function update()
{
setthumb(parseInt(id.style.left),
 		 parseInt(id.style.top),
		 parseInt(id.style.width),
		 parseInt(id.style.height)
        );

	
	
}
