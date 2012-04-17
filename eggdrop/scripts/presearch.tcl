## Search Scene Releases that have been Pre on the website www.orlydb.com ##

bind pub - .pre presearch
set chan "#fsc"

proc presearch { nick host hand chan arg } {
  if {[catch {set preSockSearch [socket -async "www.orlydb.com" 80]} sockerr]} {
    return 0 
  } else {
    set arg [string map { " " "+" } $arg]
    puts $preSockSearch "GET /?q=$arg HTTP/1.0"
    puts $preSockSearch "Host: www.orlydb.com"
    puts $preSockSearch ""
    flush $preSockSearch
    set stamp 0
    set section 0
    set release 0
    while {![eof $preSockSearch]} {   
      set prevar " [gets $preSockSearch] "
      if {[regexp {timestamp} $prevar match]} { set stamp "[string trim [prestrip $prevar]]" }
      if {[regexp {section} $prevar match ]} { set section "[string trim [prestrip $prevar]]" }
      if {[regexp {"release"} $prevar match]} { set release "[string trim [prestrip $prevar]]" }
      if {$stamp!=0 && $section!=0 && $release!=0} { 
        putserv "PRIVMSG $chan :\002($section)\002 $release ($stamp)"
        close $preSockSearch
        return 0
      }
    }
    putserv "PRIVMSG $chan :\002(orlydb)\002 Not found"
  }
  close $preSockSearch
  return 0 
}


proc prestrip {string} {
  regsub -all {<[^<>]+>} $string "" string 
  return $string
}
