################################################################################
# TVInfo Light                                                                 #
# Based on dlx's tvrage lookup script                                          #
################################################################################
#                                                                              #
# v001 (Znuff@Egghelp) - 23/08/2011                                            #
# - Initial release, stripped appart dlx's tvrage script                       #
# v002 (Robby@Egghelp) - 07/09/2011                                            #
# - Replaced replacevar with a string map (speechles)                          #
# - Fixed "Illegal characters in URL path" (speechles)                         #
# - Added a message saying we're querying the server so users know the bot     #
#   got the command and isn't lagging on them                                  #
# - Return on error to prevent further erroneous processing, stops and fixes   #
#   a "no such variable" error                                                 #
# - In the tvlast proc: added a missing else, fixing a "no such variable"      #
#   error                                                                      #
# - Fixed a "no such variable" error in the tv proc                            #
# - Added ability to enable/disable this script per channel through .chanset,  #
#   +tv to enable, -tv to disable                                              #
#   NOTE: At first this will be disabled for all channels, so you will have    #
#         to enable this for all the channels you want the script to work on   #
# - Put variables/settings in an array called: tv                              #
# - Clean up script indentation, some excess spaces and some other minor stuff #
# - Increased default timeout to 30000 as TVRage can be very slow to respond   #
# v003 (Robby@Egghelp) - 16/12/2011                                            #
# - Fixed an error if episode titles contained a ’ character                   #
# - Fixed a bug if genres contained a - or / character, it would cut off the   #
#   the remaining part of the line output (found by Arkadietz@Egghelp)         #
#                                                                              #
################################################################################

bind pub -|- .tv tv

# Timeout value - in milliseconds
set tv(timeout) "30000"

# Set a prefix for the output, you can use %bull, %bold, %uline and %color
# No trailing space needed.
set tv(prefix) "TV:"

set tv(version) "003"
setudef flag tv

proc showinfo {chan arg} {
  global tv
  set arg "$tv(prefix) $arg"
  set arg [string map [list "%bold" "\002" "%uline" "\037" "%bull" "\u2022" "%color" "\003"] $arg]
  set arg [encoding convertto utf-8 $arg]
  putquick "PRIVMSG $chan :$arg"
}

proc tv {nick host hand chan arg} {
  if {![channel get $chan tv]} {return 0}

  global tv
  package require http

  #putquick "PRIVMSG $chan :$tv(prefix) Querying TVRage server..."

  set arg [string map {" " "_"} $arg]

  set url "http://services.tvrage.com/tools/quickinfo.php?show=[::http::formatQuery $arg]"
  set page [http::data [http::geturl $url -timeout $tv(timeout)]]

  regexp {Show Name@([A-Za-z 0-9\&\':]+)} $page gotname show_name
  #regexp {Latest Episode@([0-9x]+)\^([A-Za-z0-9 -\`\’\"\'\&:\.,]+)\^([A-Za-z0-9/]+)} $page gotlatest latest_ep latest_ep_title latest_ep_date
  #set gotnext [regexp {Next Episode@([0-9x]+)\^([A-Za-z0-9 -\`\’\"\'\&:.,]+)\^([A-Za-z0-9/]+)} $page gotnext next_ep next_ep_title next_ep_date]
  regexp {Latest Episode@([0-9x]+)\^([A-Za-z0-9 -\`\"\'\&:\.,]+)\^([A-Za-z0-9/]+)} $page gotlatest latest_ep latest_ep_title latest_ep_date
  set gotnext [regexp {Next Episode@([0-9x]+)\^([A-Za-z0-9 -\`\"\'\&:.,]+)\^([A-Za-z0-9/]+)} $page gotnext next_ep next_ep_title next_ep_date]
  regexp {Airtime@([A-Za-z, 0-9:]+)} $page gotairtime show_airtime

  if {![info exists show_name]} {
    showinfo $chan "Error: Timeout."
    return 1
  }

  if {$gotnext == 0} {
    showinfo $chan "The next episode of %bold$show_name%bold is not yet scheduled."
  } else {
    showinfo $chan "The next episode of %bold$show_name%bold is %bold$next_ep_title \[$next_ep\]%bold, it will air on %bold$show_airtime $next_ep_date%bold. Previous episode was $latest_ep on $latest_ep_date."
  }

  return 1
}

putlog "TVInfo Light v$tv(version): LOADED"
