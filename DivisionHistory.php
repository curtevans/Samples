<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<?php
// An older PHP program to display Soccer Team History

$db_conn = pg_connect ("dbname=allamerican");
$SESSION=$_POST["SESSION"];
$DIVISION=$_POST["DIVISION"];

// Fetch team names and divisions

$qu = pg_exec ($db_conn, "SELECT * from teams");
$row = 0;

for ($i=0;$i<pg_numrows($qu);$i++)
{
 $data = pg_fetch_object ($qu, $row++);
 $teamlist[$data->team]=$data->name;
 $DIVISION=$data->division;
}

//Fetch the game records

$qu = pg_exec ($db_conn, "SELECT * from games where (division='$DIVISION'  and session = $SESSION) order by day");
$row = 0;
if (pg_numrows($qu)>0)
{
 for ($i=0;$i<pg_numrows($qu);$i++)
 {
  $d = pg_fetch_object ($qu, $row++);
  $final='&nbsp;';
  if ($d->final == 't')
  {$final='YES';}
  $gamebuf.='<tr><td><font size="2">'.$d->day.'</font></td><td align="center"><font size="2">'.$d->wltfhome.'</font></td><td><font size="2">'.$d->home.'</font></td><td><font size="2">'.$teamlist[$d->home].'</font></td><td align="center"><font size="2">'.$d->homegoals.'</font></td><td align="center"><font size="2">'.$d->wltfvisitor.'</font></td><td><font size="2">'.$d->visitor.'</font></td><td><font size="2">'.$teamlist[$d->visitor].'</font></td><td align="center"><font size="2">'.$d->visitorgoals.'</font></td><td></td><td align="center"><font size="2">'.$final.'</font></td></tr>';
 }
}
else
 {
  $gamebuf='<tr><td align="center" colspan="7">No games recorded</td></tr>';
 }

?>
<html>
<head>
<title>Team Game History</title>
<STYLE TYPE="text/css">

    A {
        color: #F4F8F4;
        text-decoration:none;
		font-family:verdana;
        font-weight:bold;
    }
    
    A:hover {color: #ffcc33}

</STYLE>
</head>
<script>

</script>
<body>
<p><?php echo $teamstr;?></p>
<form name="info" method="post" action="/cgi/putsched.pl">
 <table width="712" cellspacing="0" cellpadding="0" border="0">
 <tr> 
 <td align="center" height="25" bgcolor="#FFFFFF"> 
 <table border="0" width="100%">
 <tr> 
 <td width="10%" align="left" valign="top"><font color="#000000"><b><font size="+2"><a href="/index.html"><img src="/images/logo_sm.gif" width=55 height=27 alt="All American Indoor Sports, Inc" border="0"></a></font></b></font> 
 </td>
 <td width="90%" align="center"><font color="#000000"><b><font size="3">All American Indoor Sports<br>
 Game History<br>
 </font><font size="3"><?php echo $teamlist[$TEAM]; ?> </font></b></font></td>
 </tr>
 </table>
 </td>
 </tr>
 <tr> 
 <td align="left" valign="top" bgcolor="#FFFFFF"> 
 <table width="100%" border="0">
 <tr> 
 <td colspan="11" align="left" height="14"> 
 <hr>
 </td>
 </tr>
 <tr> 
 <td align="left" width="92"><b><font size="2">Date</font></b></td>
 <td align="left" width="64"><b><font color="#000000" size="2">&nbsp;W/L/T/F&nbsp;</font></b></td>
 <td align="left" width="10"><font size="2"></font></td>
 <td align="left" width="125"><b><font size="2">Home</font></b></td>
 <td align="left" width="47"><b><font size="2">Goals&nbsp; </font></b></td>
 <td align="left" width="64"><b><font color="#000000" size="2">&nbsp;W/L/T/F</font></b></td>
 <td align="left" width="10"><font size="2"></font></td>
 <td align="left" width="142"><b><font size="2">Visitor</font></b></td>
 <td align="left" width="45"><b><font size="2">Goals&nbsp;</font></b></td>
 <td align="left" width="20"><font size="2"></font></td>
 <td align="left" width="70"><b><font size="2">Playoff</font></b></td>
 </tr>
 <?php echo $gamebuf;?>
 </table>
 </td>
 </tr>
 <tr> 
 <td height="108" bgcolor="#FFFFFF">&nbsp;</td>
 </tr>
 </table>
 <p>&nbsp;</p>
</form>
</body>
</html>
