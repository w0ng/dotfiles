# IMDb query v1.15 (updated by username@egghelp.org forums)
# Copyright (C) 2007-2009 perpleXa
# http://perplexa.ugug.org / #perpleXa on QuakeNet
#
# Redistribution, with or without modification, are permitted provided
# that redistributions retain the above copyright notice, this condition
# and the following disclaimer.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, to the extent permitted by law; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.
#
# Usage:
#  !movie <title>

package require http 2.7; # TCL 8.5

namespace eval imdb {
  variable version 1.15;
  # flood protection (seconds)
  variable antiflood "10";
  # character encoding
  variable encoding "utf-8";
  # user agent
  variable agent "Mozilla/5.0 (X11; U; Linux i686; en-GB; rv:1.8.1) Gecko/2006101023 Firefox/2.0";

  # internal
  bind pub -|- ".imdb" [namespace current]::public;
  bind msg -|- ".imdb" [namespace current]::private;
  variable flood;
  namespace export *;
}

proc imdb::public {nick host hand chan argv} {
  imdb::main $nick $host $hand $chan $argv
}

proc imdb::private {nick host hand argv} {
  imdb::main $nick $host $hand $nick $argv
}

proc imdb::main {nick host hand chan argv} {
  variable flood; variable antiflood;
  if {![info exists flood($chan)]} { set flood($chan) 0; }
  if {[unixtime] - $flood($chan) <= $antiflood} { return 0; }
  set flood($chan) [unixtime];

  set argv [string trim $argv];
  if {$argv == ""} {
    puthelp "NOTICE $nick :\002Syntax\002: $::lastbind <title>";
    return 0;
}

set id [id $argv];
if {$id == ""} {
  chanmsg $chan "Movie not found: $argv";
  return 0;
}

set info [getinfo $id];
if {![llength $info]} {
  chanmsg $chan "Couldn't get information for movie id $id$.";
  return 0;
}

for {set i 0} {$i < [llength $info]} {incr i} {
  set info [lreplace $info $i $i [decode [lindex $info $i]]];
}

set name      [lindex $info 0]; 
set year      [lindex $info 1];
set dir       [lindex $info 2];
set genre     [lindex $info 3];
set language  [lindex $info 4];
set rating    [lindex $info 5];
set stars     [lindex $info 6];
set countryy  [lindex $info 7]; 

if {$name == ""} {
  chanmsg $chan "Couldn't get information for movie id $id.";
  return 0;
}

if {$rating == "-"} {
  set rating_ 0
} else {
  set rating_ $rating
}
chanmsg $chan "\002$name\002:: \002Rating:\002 $rating/10 :: \002Country:\002 $countryy :: \002Language\002: $language :: \002Director\002: $dir :: \002Stars\002: $stars :: \002Genre\002: $genre :: \002Link\002: http://imdb.com/title/$id";
}

proc imdb::chanmsg {chan text} {
  if {[validchan $chan]} {
    if {[string first "c" [lindex [split [getchanmode $chan]] 0]] >= 0} {
      regsub -all {(?:\002|([0-9]{1,2}(,[0-9]{1,2})?)?|\017|\026|)} $text "" text;
  }
}
putquick "PRIVMSG $chan :$text";
}

proc imdb::id {movie} {
  variable agent;
  http::config -useragent $agent;
  if {[catch {http::geturl "http://www.imdb.com/find?q=[urlencode $movie];s=tt;site=aka" -timeout 20000} token]} {
    return;
}
set data [http::data $token];
set code [http::ncode $token];
set meta [http::meta $token];
http::cleanup $token;
if {$code == 200} {
  set id "";
  regexp -nocase -- {<a href="/title/(tt[0-9]+)/"} $data -> id;
  return $id;
} else {
  foreach {var val} $meta {
    if {![string compare -nocase "Location" $var]} {
      regexp -nocase {tt\d+} $val val;
      return $val;
    }
  }
}
}

proc imdb::getinfo {id} {
  variable agent;
  http::config -useragent $agent;
  if {[catch {http::geturl "http://www.imdb.com/title/$id/" -timeout 20000} token]} {
    return;
}
set data [http::data $token];
regsub -all -- {\r|\n} $data "" data;
http::cleanup $token;

set name ""; set year ""; set countryy ""; set dir ""; set genre "";
set rating 0; set runtime ""; set language ""; set stars "";

### Main.
regexp -nocase -- {<a href="/year/.*?/">(.*?)</a>.*?<span class="title-extra">\n(.*?)<i>} $data -> year name;
regsub -all {<.*?>} $year {} year
regsub -all {<.*?>} $name {} name

if {$name == ""} {
  regexp -nocase -- {<h1 class="header".*?>(.*?)<span>} $data -> name;
  regsub -all {<.*?>} $name {} name        

}
if {$year == ""} {
  regexp -nocase -- {<a href="/year/.*?/">(.*?)</a>} $data -> year;
  regsub -all {<.*?>} $year {} year
 }

 regexp -nocase -- {<div class="txt-block">.*?</h4>(.*?)</div>} $data -> dir;
 regsub -all "<.*?>" $dir "" dir

 ### Stars.
 regexp -nocase -- {Stars:</h4>(.*?)</div>} $data -> stars_;
 foreach {null star} [regexp -all -nocase -inline -- {<a    onclick.*?>(.*?)</a>} $stars_] {
   lappend stars [string trim $star]
}

regexp {<div class="txt-block">.*?<h4 class="inline">Country:</h4>(.*?)</div>} $data "" countryy;
regsub -all {<.*?>} $countryy {} countryy

foreach {null gen} [regexp -all -nocase -inline -- {<div class="see-more inline canwrap">.*?<h4 class="inline">Genres:</h4>(.*?)</div>} $data] {
  lappend genre [string trim $gen]
  regsub -all {<.*?>} $genre {} genre
}

### Details.
foreach {null lang} [regexp -all -nocase -inline -- {<div class="txt-block">.*?<h4 class="inline">Language:</h4>(.*?)</div>} $data] {
  lappend language [string trim $lang];
  regsub -all {<.*?>} $language {} language
}

### Technical Specs.
regexp -nocase -- {<span itemprop="ratingValue">(.*?)</span>} $data -> rating;

return [list [string trim $name] $year [string trim $dir] [join $genre "/"] [join $language "/"] $rating [join $stars "/"] [join $countryy "/"]];
}

proc imdb::urlencode {i} {
  variable encoding
  set index 0;
  set i [encoding convertto $encoding $i]
  set length [string length $i]
  set n ""
  while {$index < $length} {
    set activechar [string index $i $index]
    incr index 1
    if {![regexp {^[a-zA-Z0-9]$} $activechar]} {
      append n %[format "%02X" [scan $activechar %c]]
  } else {
    append n $activechar
  }
}
return $n
}

proc imdb::decode {content} {
  if {$content == ""} {
    return "n/a";
}
if {![string match *&* $content]} {
  return $content;
}
set escapes {
  &nbsp; \x20 &quot; \x22 &amp; \x26 &apos; \x27 &ndash; \x2D
  &lt; \x3C &gt; \x3E &tilde; \x7E &euro; \x80 &iexcl; \xA1
  &cent; \xA2 &pound; \xA3 &curren; \xA4 &yen; \xA5 &brvbar; \xA6
  &sect; \xA7 &uml; \xA8 &copy; \xA9 &ordf; \xAA &laquo; \xAB
  &not; \xAC &shy; \xAD &reg; \xAE &hibar; \xAF &deg; \xB0
  &plusmn; \xB1 &sup2; \xB2 &sup3; \xB3 &acute; \xB4 &micro; \xB5
  &para; \xB6 &middot; \xB7 &cedil; \xB8 &sup1; \xB9 &ordm; \xBA
  &raquo; \xBB &frac14; \xBC &frac12; \xBD &frac34; \xBE &iquest; \xBF
  &Agrave; \xC0 &Aacute; \xC1 &Acirc; \xC2 &Atilde; \xC3 &Auml; \xC4
  &Aring; \xC5 &AElig; \xC6 &Ccedil; \xC7 &Egrave; \xC8 &Eacute; \xC9
  &Ecirc; \xCA &Euml; \xCB &Igrave; \xCC &Iacute; \xCD &Icirc; \xCE
  &Iuml; \xCF &ETH; \xD0 &Ntilde; \xD1 &Ograve; \xD2 &Oacute; \xD3
  &Ocirc; \xD4 &Otilde; \xD5 &Ouml; \xD6 &times; \xD7 &Oslash; \xD8
  &Ugrave; \xD9 &Uacute; \xDA &Ucirc; \xDB &Uuml; \xDC &Yacute; \xDD
  &THORN; \xDE &szlig; \xDF &agrave; \xE0 &aacute; \xE1 &acirc; \xE2
  &atilde; \xE3 &auml; \xE4 &aring; \xE5 &aelig; \xE6 &ccedil; \xE7
  &egrave; \xE8 &eacute; \xE9 &ecirc; \xEA &euml; \xEB &igrave; \xEC
  &iacute; \xED &icirc; \xEE &iuml; \xEF &eth; \xF0 &ntilde; \xF1
  &ograve; \xF2 &oacute; \xF3 &ocirc; \xF4 &otilde; \xF5 &ouml; \xF6
  &divide; \xF7 &oslash; \xF8 &ugrave; \xF9 &uacute; \xFA &ucirc; \xFB
  &uuml; \xFC &yacute; \xFD &thorn; \xFE &yuml; \xFF
};
set content [string map $escapes $content];
set content [string map [list "\]" "\\\]" "\[" "\\\[" "\$" "\\\$" "\\" "\\\\"] $content];
regsub -all -- {&#([[:digit:]]{1,5});} $content {[format %c [string trimleft "\1" "0"]]} content;
regsub -all -- {&#x([[:xdigit:]]{1,4});} $content {[format %c [scan "\1" %x]]} content;
regsub -all -- {&#?[[:alnum:]]{2,7};} $content "?" content;
return [subst $content];
}

putlog "*IMDb v$imdb::version* Loaded"
