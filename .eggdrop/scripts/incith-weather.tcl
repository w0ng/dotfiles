#---------------------------------------------------------------------#
# incith:weather                                                 v2.9a#
#                                                                     #
# retrieves weather and forecast data from www.wunderground.com       #
# tested on Eggdrop v1.6.18                                           #
#                                                                     #
# Usage:                                                              #
#   .chanset #channel +weather                                        #
#   !weather <search>                                                 #
#     returns the current conditions for the city found               #
#   !forecast <search>                                                #
#     returns a 3-day forecast for the city found                     #
#   !sky <location>                                                   #
#     returns the astronomy data for the city found                   #
#                                                                     #
# Forum Support:                                                      #
#   http://forum.egghelp.org/viewtopic.php?t=10466                    #
#                                                                     #
# ChangeLog:                                                          #
#   2.0: script re-created.  more updates to come.                    #
#   2.1: option for update time to be displayed in 24-hour (default)  #
#         - this removes AM/PM and the timezone if enabled            #
#        more informative locations                                   #
#        uses mobile.wunderground.com for forecast data if it has to  #
#   2.2: fix for updated time.                                        #
#   2.3: can use !w/!fc -set <location> to store a default, if you're #
#          an added member of the bots userlist (only way for now).   #
#        small fix for updated time on some locations preventing      #
#          results from being sent, igloolik was one such city.       #
#   2.4: added new variable 'public_to_private' to control whether    #
#          replies are sent to the channel or to the user requesting. #
#        if it is set, the user will get /msg'd with the results, or  #
#          they will get /notice'd if variable 'notices' is set to 1. #
#  2.5a: fixed high/low showing yesterdays data sometimes.. also if   #
#          todays forecast is not available it will try mobiles.      #
#   2.6: moved error checking higher up in fetch_html, fixes london.  #
#        convert EEST to EET to as Tcl does not recognize EEST (?)    #
#          this fixes any location with EEST.                         #
#  2.6a: there should never be a clock issue again as timezones are   #
#          no longer being used in calculations, at all.              #
#   2.7: astronomy is back, !sky <location>                           #
#        multiple results problem fixed (hull, united kingdom).       #
#        variable weather_format controls which weather data's sent.  #
#        forecast_format controls which forecast data's sent.         #
#        pressure has been added back to !weather (%w9%).             #
#        fixed a bug in the way i was grabbing wind direction         #
#          basically, it wasn't showing 'Calm' when it actually was.  #
#        <country> searches (!w malaysia for example) will now return #
#          multiple results correctly.                                #
#        wunderground seems to have gone to a 3-day forecast for most #
#          locations, so I've modified the script accordingly.        #
#        tries to fetch the current local time and date for accurate  #
#          high/low display.                                          #
#  2.7a: oops, small fix for 'unable to convert date time string'     #
#   2.8: fixed multiple results (especially !w india).                #
#          this works now by stripping locations without temperatures #
#        no more 'cannot read (update_time)' in multiple results.     #
#  2.8a: more multiple results fixes.                                 #
#  2.8b: more multiple results fixes.  woot.                          #
#  2.8c: fixed conditions/location/todays_day/UV, and astronomy.      #
#  2.8d: more fixes for forecast and location.                        #
#  2.8e: wunderground changed something that broke forecast; fixed.   #
#  2.8f: fixed a bug for the location 'unknown' and similar results.  #
#        changed flood protection to ignore +f flagged users.         #
#        wunderground removed <nobr> tags breaking a lot of things.   #
#        fixed locations that have blank sunrise/sunset data.         #
#  2.8g: removed <nobr> tags from html to fix things breaking again.  #
#  2.8h: fixed multiple results (they changed the layout).  again.    #
#  2.8i: it's not my fault, honest!  more multiple results fixes.     #
#  2.8j: fixes: temp, dew point, wind speed, better mobile backup.    #
#  2.8k: added longitude & latitude back (optional, show_lat_lon var) #
#        major improvements to multiple results.                      #
#        forecast will show the % chance of precipitation.            #                       
#        script was fetching mobile more often than it needed, fixed. #
#  2.8L: forecast modified for unknown change, capital L for LOLS!    #
#  2.8m: more small fixes and updates.                                #
#  2.8n: windchill fix.                                               #
#  2.8o: they made units cookie based, fix to compensate.             #
#  2.8p: fix for public_to_private not working.                       #
#  2.8q: Correct missing celsius information, current weather only    #
#        returns farenheight. Script now converts on it's own.        #
#  2.8r: Added "nickname" prefixes to commands optional. default is on#
#   2.9: Correct missing celsius info for dewpoint. same fix as temp. #
#  2.9a: Corrected the way I was removing extraneous decimel points   #
#        and ending 0's.                                              #
#                                                                     #
# Contact:                                                            #
#   E-mail (incith@gmail.com) cleanups, ideas, bugs, etc., to me.     #
#                                                                     #
# TODO:                                                               #
#   - locales for output (languages)                                  #
#   + fix multiple results, take best match, etc                      #
#   + user defaults (so we can just !weather)                         #
#   - seperate proc for forecast fetching, to speed up results        #
#     - theoretically :)                                              #
#   - forecast updated time                                           #
# - merge _handlers, allow all %var% in all _formats, max_results     #
# - limit size of output, check length of variables?                  #
#                                                                     #
# LICENSE:                                                            #
#   This code comes with ABSOLUTELY NO WARRANTY.                      #
#                                                                     #
#   This program is free software; you can redistribute it and/or     #
#   modify it under the terms of the GNU General Public License as    #
#   published by the Free Software Foundation; either version 2 of    #
#   the License, or (at your option) any later version.               #
#   later version.                                                    #
#                                                                     #
#   This program is distributed in the hope that it will be useful,   #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of    #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.              #
#                                                                     #
#   See the GNU General Public License for more details.              #
#   (http://www.gnu.org/copyleft/library.txt)                         #
#                                                                     #
# Copyleft (C) 2005-10, Jordan                                        #
# incith@gmail.com (paypal donations accepted)                        #
# irc.freenode.net / #incith                                          #
#---------------------------------------------------------------------#
package require http 2.3
setudef flag weather

namespace eval incith {
  namespace eval weather {
    # the bind prefix/command char ("!" or ".", etc)
    variable command_char "."

    # binds ("one two three") as many as you need
    variable weather_binds "w"
    variable forecast_binds ""
    variable astronomy_binds ""
    variable time_binds ""

    # if you want to change the order or remove some items that are sent
    #  w0 - location, w1 - updated,  w2 - conditions, w3 - temperature, w4 - windchill
    #  w5 - high/low, w6 - humidity, w7 - dew point,  w8 - UV index,    w9 - pressure
    # w10 - wind, nick - nickname of user triggering
    variable weather_format "%w0% %w3% %w5% %w6% %w2% %w1%"

    # some control over the forecast format, too
    # f0 - location,  f1 - updated,    f2 - first day high/low, f3 - second day high/low
    # f4 - third day, f5 - fourth day, f6 - fifth day
    # nick - nickname of user triggering
    variable forecast_format "%nick% %f0% %f1% %f2% %f3% %f4% %f5% %f6%"

    # some control over the time format, too
    # w0 - location, w1 - local time
    variable time_format "%nick% %w0% %w1%"

    # show latitude and longitude for locations?
    variable show_lat_lon 0

    # symbol to put beside temperature numbers
    variable degree_symbol "°"

    # display celcius temperatures first, and fahrenheit in ()
    variable celcius_first 0

    # allow binds to be used in /msg's to the bot?
    variable private_messages 0

    # send public/channel replies to the user instead of to the channel?
    variable public_to_private 0

    # send replies as notices instead of messages?
    variable notices 0

    # this will be used to seperate items (Foo; Bar; Baz)
    # setting this to "\n" will have *everything* on a new line
    variable seperator "; "

    # use this if you would only like to break results into 3 new lines
    variable seperate_lines 0

    # convert update time into 24-hour time
    variable 24hour_time 0

    # weather granularity
    # Enter the amount of digits after the decimal point you want
    variable granularity 0

    # make use of bolding where appropriate?
    variable bold 1

    # the maximum length a line sent should be
    variable split_length "403"

    # if you're using a proxy, enter it here (proxy.example.com:3128)
    variable proxy ""

    # how long (in seconds) before the http request times out?
    variable timeout 15

    # number of minute(s) to ignore flooders, 0 to disable flood protection
    variable ignore 1

    # prefix results with nickname?
    variable usenicks 1

    # how many requests in how many seconds is considered flooding?
    # by default, this allows 3 queries in 10 seconds, the 4th being ignored
    #   and ignoring requests for 'variable ignore' minutes
    variable flood 4:10
  }
}

# script begings
namespace eval incith {
  namespace eval weather {
    variable version "incith:weather-2.9a"
    variable debug 0
  }
}

# bind the binds
foreach bind [split ${incith::weather::weather_binds} " "] {
  # public message binds
  bind pub -|- "${incith::weather::command_char}${bind}" incith::weather::weather_handler

  # private message binds
  if {${incith::weather::private_messages} >= 1} {
    bind msg -|- "${incith::weather::command_char}${bind}" incith::weather::weather_handler
  }
}
foreach bind [split ${incith::weather::forecast_binds} " "] {
  # public message binds
  bind pub -|- "${incith::weather::command_char}${bind}" incith::weather::forecast_handler

  # private message binds
  if {${incith::weather::private_messages} >= 1} {
    bind msg -|- "${incith::weather::command_char}${bind}" incith::weather::forecast_handler
  }
}
foreach bind [split ${incith::weather::astronomy_binds} " "] {
  # public message binds
  bind pub -|- "${incith::weather::command_char}${bind}" incith::weather::astronomy_handler

  # private message binds
  if {${incith::weather::private_messages} >= 1} {
    bind msg -|- "${incith::weather::command_char}${bind}" incith::weather::astronomy_handler
  }
}
foreach bind [split ${incith::weather::time_binds} " "] {
  # public message binds
  bind pub -|- "${incith::weather::command_char}${bind}" incith::weather::time_handler

  # private message binds
  if {${incith::weather::private_messages} >= 1} {
    bind msg -|- "${incith::weather::command_char}${bind}" incith::weather::time_handler
  }
}

namespace eval incith {
  namespace eval weather {
    # [custom_format] : converts a string to the desired output
    #
    proc custom_format {htmla type input nick} {
      array set html $htmla

      # for seperate line results option
      if {${incith::weather::seperate_lines} >= 1} {
        set alternate_sep "\n"
      } else {
        set alternate_sep ${incith::weather::seperator}
      }
      # spaces make things look wrong
      regsub -all {\s+} $input {} input

      if {$::incith::weather::usenicks > 0 } {
        set input [string map [list %nick% "\002$nick's\002 $type request"] $input]
      } else {
        set input [string map [list %nick% ""] $input]
      }
      if {$type == "weather"} {
        if {[info exists html(location)]} {
          if {[info exists html(latitude)] && [info exists html(longitude)] && $incith::weather::show_lat_lon >= 1} {
            set input [string map "{%w0%} {${incith::weather::seperator}[ibold $html(location)] ($html(latitude)\/$html(longitude))}" $input]
          } else {
            set input [string map "{%w0%} {${incith::weather::seperator}[ibold $html(location)]}" $input]
          }
        } else {
          set input [string map "{%w0%} {}" $input]
        }

        if {[info exists html(update_time)] && [info exists html(update_date)]} {
          set input [string map "{%w1%} {${incith::weather::seperator}[ibold "Updated:"] $html(update_time) $html(update_timezone) ($html(update_date))}" $input]
        } else {
          set input [string map "{%w1%} {}" $input]
        }

        if {[info exists html(conditions)] && [string length $html(conditions)] >= 1} {
          set input [string map "{%w2%} {${incith::weather::seperator}[ibold "Conditions:"] $html(conditions)}" $input]
        } else {
          set input [string map "{%w2%} {}" $input]
        }

        if {[info exists html(tempf)] && [info exists html(tempc)]} {
          set input [string map "{%w3%} {${alternate_sep}[ibold "Temperature:"] [i2fac $html(tempf) $html(tempc)]}" $input]
        } else {
          set input [string map "{%w3%} {}" $input]
        }

        if {[info exists html(windchillf)] && [info exists html(windchillc)]} {
          set input [string map "{%w4%} {${incith::weather::seperator}[ibold "Windchill:"] [i2fac $html(windchillf) $html(windchillc)]}" $input]
        } else {
          set input [string map "{%w4%} {}" $input]
        }

        # compare the date the weather was updated to output todays high/low
        if {([info exists html(fc1d)]) && $html(fc1d) == $html(todays_day)} {
          set input [string map "%w5% {${incith::weather::seperator}[ibold "High/Low:"] [if2c $html(fc1hf) $html(fc1lf)]}" $input]
        } elseif {([info exists html(fc2d)]) && $html(fc2d) == $html(todays_day)} {
          set input [string map "%w5% {${incith::weather::seperator}[ibold "High/Low:"] [if2c $html(fc2hf) $html(fc2lf)]}" $input]
        } elseif {([info exists html(fc3d)]) && $html(fc3d) == $html(todays_day)} {
          set input [string map "%w5% {${incith::weather::seperator}[ibold "High/Low:"] [if2c $html(fc3hf) $html(fc3lf)]}" $input]
        } elseif {([info exists html(fc4d)]) && $html(fc4d) == $html(todays_day)} {
          set input [string map "%w5% {${incith::weather::seperator}[ibold "High/Low:"] [if2c $html(fc4hf) $html(fc4lf)]}" $input]
        } elseif {([info exists html(fc5d)]) && $html(fc5d) == $html(todays_day)} {
          set input [string map "%w5% {${incith::weather::seperator}[ibold "High/Low:"] [if2c $html(fc5hf) $html(fc5lf)]}" $input]
        } else {
          set input [string map "%w5% {${incith::weather::seperator}[ibold "High/Low:"] Unavailable}" $input]
        }

        if {[info exists html(humidity)]} {
          set input [string map "{%w6%} {${incith::weather::seperator}[ibold "Humidity:"] $html(humidity)%}" $input]
        } else {
          set input [string map "{%w6%} {}" $input]
        }

        if {[info exists html(dewf)] && [info exists html(dewc)]} {
          set input [string map "{%w7%} {${alternate_sep}[ibold "Dew Point:"] [i2fac $html(dewf) $html(dewc)]}" $input]
        } else {
          set input [string map "{%w7%} {}" $input]
        }

        if {[info exists html(uv_min)] && [info exists html(uv_max)]} {
          set input [string map "{%w8%} {${incith::weather::seperator}[ibold "UV:"] $html(uv_min)\/$html(uv_max)}" $input]
        } else {
          set input [string map "{%w8%} {}" $input]
        }

        if {[info exists html(pressure_hpa)] && [info exists html(pressure_in)]} {
          set input [string map "{%w9%} {${incith::weather::seperator}[ibold "Pressure:"] ${html(pressure_in)} in\/${html(pressure_hpa)} hPa}" $input]
        } else {
          set input [string map "{%w9%} {}" $input]
        }

        if {[info exists html(windd)]} {
          set temp_wind "${incith::weather::seperator}[ibold "Wind:"] $html(windd)"
          if {[info exists html(windm)] && [info exists html(windk)]} {
            if {${incith::weather::celcius_first} >= 1} {
              append temp_wind " at $html(windk) KPH ($html(windm) MPH)"
            } else {
              append temp_wind " at $html(windm) MPH ($html(windk) KPH)"
            }
          }
          set input [string map "{%w10%} {${temp_wind}}" $input]
        } else {
          set input [string map "{%w10%} {}" $input]
        }

        regsub -- "^\\s*${incith::weather::seperator}" $input {} input
        return $input
      } elseif {$type == "forecast"} {
        if {[info exists html(location)]} {
          set input [string map "{%f0%} {${incith::weather::seperator}[ibold "$html(location) Forecast"] (High/Low)}" $input]
        } else {
          set input [string map "{%f0%} {}" $input]
        }

        if {[info exists html(update_time)] && [info exists html(update_date)]} {
          set input [string map "{%f1%} {${incith::weather::seperator}[ibold "Updated:"] $html(update_time) $html(update_timezone) ($html(update_date))}" $input]
        } else {
          set input [string map "{%f1%} {}" $input]
        }

        # prepend the chance of precipitation if necessary
        if {[info exists html(fc1chance)]} {
          set html(fc1c) "$html(fc1chance) $html(fc1c)"
        }
        if {[info exists html(fc2chance)]} {
          set html(fc2c) "$html(fc2chance) $html(fc2c)"
        }
        if {[info exists html(fc3chance)]} {
          set html(fc3c) "$html(fc3chance) $html(fc3c)"
        }
        if {[info exists html(fc4chance)]} {
          set html(fc4c) "$html(fc4chance) $html(fc4c)"
        }
        if {[info exists html(fc5chance)]} {
          set html(fc5c) "$html(fc5chance) $html(fc5c)"
        }

        if {[info exists html(fc1hf)] && [info exists html(fc1lf)] && [info exists html(fc1c)]} {
          set input [string map "{%f2%} {${incith::weather::seperator}[ibold "$html(fc1d):"] $html(fc1c), [if2c $html(fc1hf) $html(fc1lf)]}" $input]
        } else {
          set input [string map "{%f2%} {}" $input]
        }
        if {[info exists html(fc2hf)] && [info exists html(fc2lf)] && [info exists html(fc2c)]} {
          set input [string map "{%f3%} {${alternate_sep}[ibold "$html(fc2d):"] $html(fc2c), [if2c $html(fc2hf) $html(fc2lf)]}" $input]
        } else {
          set input [string map "{%f3%} {}" $input]
        }
        if {[info exists html(fc3hf)] && [info exists html(fc3lf)] && [info exists html(fc3c)]} {
          set input [string map "{%f4%} {${incith::weather::seperator}[ibold "$html(fc3d):"] $html(fc3c), [if2c $html(fc3hf) $html(fc3lf)]}" $input]
        } else {
          set input [string map "{%f4%} {}" $input]
        }
        if {[info exists html(fc4hf)] && [info exists html(fc4lf)] && [info exists html(fc4c)]} {
          set input [string map "{%f5%} {${incith::weather::seperator}[ibold "$html(fc4d):"] $html(fc4c), [if2c $html(fc4hf) $html(fc4lf)]}" $input]
        } else {
          set input [string map "{%f5%} {}" $input]
        }
        if {[info exists html(fc5hf)] && [info exists html(fc5lf)] && [info exists html(fc5c)]} {
          set input [string map "{%f6%} {${incith::weather::seperator}[ibold "$html(fc5d):"] $html(fc5c), [if2c $html(fc5hf) $html(fc5lf)]}" $input]
        } else {
          set input [string map "{%f6%} {}" $input]
        }
        regsub -- "^\\s*${incith::weather::seperator}" $input {} input
        return $input
	} elseif {$type == "time"} {
	  if {[info exists html(local_timezone)] && [info exists html(local_date)] && [info exists html(local_timezone)]} {
          set input [string map "{%w1%} {${incith::weather::seperator}[ibold "Local Time:"] $html(local_time) $html(local_timezone) ($html(update_date))}" $input]
        } else {
          set input [string map "{%w1%} {}" $input]
        }
        if {[info exists html(location)]} {
          if {[info exists html(latitude)] && [info exists html(longitude)] && $incith::weather::show_lat_lon >= 1} {
            set input [string map "{%w0%} {${incith::weather::seperator}[ibold $html(location)] ($html(latitude)\/$html(longitude))}" $input]
          } else {
            set input [string map "{%w0%} {${incith::weather::seperator}[ibold $html(location)]}" $input]
          }
        } else {
          set input [string map "{%w0%} {}" $input]
        }
        regsub -- "^\\s*${incith::weather::seperator}" $input {} input
        return $input
      } else {
        return 0
      }
    }

    # [time_handler] : handles public & private messages for !time
    #
    proc time_handler {nick uhand hand args} {
      if {[llength $args] >= 2} { # public message
        if {${incith::weather::public_to_private} >= 1} {
          set where $nick
        } else {
          set where [lindex $args 0]
          if {[lsearch -exact [channel info $where] +weather] == -1} {
            return
          }
        }
        set chan [lindex $args 0]
        set input [lindex $args 1]
      } else {			  # private message
        set where $nick
        set chan "private"
        set input [lindex $args 0]
        if {${incith::weather::private_messages} <= 0} {
          return
        }
      }

      # flood protection
      if {[flood $nick $uhand $hand $where]} {
        return
      }

      # user defaults, user must exist as a user on the bot
      if {[lindex $input 0] == "-set"} {
        if {[validuser $hand]} { 
          setuser $hand XTRA incith:weather.location "[lrange $input 1 end]"
          send_output $nick "Default weather location set to [lrange $input 1 end]."
          return
        } else {
          send_output $nick "Sorry, your bot handle was not found.  Unable to set a default."
          return
        }
        set input [lrange $input 1 end]
      } elseif {[regexp -- "^\\s*$" $input] && [validuser $hand]} {
        set input [getuser $hand XTRA incith:weather.location]
      }

      # log it
      putlog "${incith::weather::version}: <${nick}/${chan}> ${incith::weather::command_char}time $input"

      # no input given
      if {[regexp -- "^\\s*$" $input]} {
        send_output $where "Please visit http://classic.wunderground.com for more details on searching methods."
        return
      }

      # fetch the html
      array set html [fetch_html $input]

      # check for html's existence
      if {[info exists html(error)]} {
        send_output $where $html(error)
        return
      }

      # for seperate line results option
      if {${incith::weather::seperate_lines} >= 1} {
        set alternate_sep "\n"
      } else {
        set alternate_sep ${incith::weather::seperator}
      }


      # make sure we have data to send, and send it
      set reply [custom_format [array get html] "time" $incith::weather::time_format $nick]
      if {$reply == "0"} { unset reply }
      if {[info exists reply]} {
        send_output $where $reply
      } else {
        send_output $where "There was a problem while attempting to parse the data."
      }
    }

    # [weather_handler] : handles public & private messages for !weather
    #
    proc weather_handler {nick uhand hand args} {
      if {[llength $args] >= 2} { # public message
        if {${incith::weather::public_to_private} >= 1} {
          set where $nick
        } else {
          set where [lindex $args 0]
          if {[lsearch -exact [channel info $where] +weather] == -1} {
            return
          }
        }
        set chan [lindex $args 0]
        set input [lindex $args 1]
      } else {			  # private message
        set where $nick
        set chan "private"
        set input [lindex $args 0]
        if {${incith::weather::private_messages} <= 0} {
          return
        }
      }

      # flood protection
      if {[flood $nick $uhand $hand $where]} {
        return
      }

      # user defaults, user must exist as a user on the bot
      if {[lindex $input 0] == "-set"} {
        if {[validuser $hand]} { 
          setuser $hand XTRA incith:weather.location "[lrange $input 1 end]"
          putserv "notice $nick :Default weather location set to [lrange $input 1 end]"
          return
        } else {
          putserv "notice $nick :Sorry, your bot handle was not found.  Unable to set a default until you are known. Who are you?"
          return
        }
        set input [lrange $input 1 end]
      } elseif {[regexp -- "^\\s*$" $input] && [validuser $hand]} {
        set input [getuser $hand XTRA incith:weather.location]
      }

      # log it
      putlog "${incith::weather::version}: <${nick}/${chan}> ${incith::weather::command_char}weather $input"

      # no input given
      if {[regexp -- "^\\s*$" $input]} {
        send_output $where "Please visit http://classic.wunderground.com for more details on searching methods."
        return
      }

      # fetch the html
      array set html [fetch_html $input]

      # check for html's existence
      if {[info exists html(error)]} {
        send_output $where $html(error)
        return
      }

      # for seperate line results option
      if {${incith::weather::seperate_lines} >= 1} {
        set alternate_sep "\n"
      } else {
        set alternate_sep ${incith::weather::seperator}
      }


      # make sure we have data to send, and send it
      set reply [custom_format [array get html] "weather" $incith::weather::weather_format $nick]
      if {$reply == "0"} { unset reply }
      if {[info exists reply]} {
        send_output $where $reply
      } else {
        send_output $where "There was a problem while attempting to parse the data."
      }
    }


    # [forecast_handler] : handles forecast requests
    #
    proc forecast_handler {nick uhand hand args} {
      if {[llength $args] >= 2} { # public message
        if {${incith::weather::public_to_private} >= 1} {
          set where $nick
        } else {
          set where [lindex $args 0]
          if {[lsearch -exact [channel info $where] +weather] == -1} {
            return
          }
        }
        set chan [lindex $args 0]
        set input [lindex $args 1]
      } else {			  # private message
        set where $nick
        set chan "private"
        set input [lindex $args 0]
        if {${incith::weather::private_messages} <= 0} {
          return
        }
      }

      # flood protection
      if {[flood $nick $uhand $hand $where]} {
        return
      }

      # user defaults, user must exist as a user on the bot
      if {[lindex $input 0] == "-set"} {
        if {[validuser $hand]} { 
          setuser $hand XTRA incith:weather.location "[lrange $input 1 end]"
          send_output $nick "Default weather location set to [lrange $input 1 end]."
          return
        } else {
          send_output $nick "Sorry, your bot handle was not found.  Unable to set a default."
        }        
        set input [lrange $input 1 end]
      } elseif {[regexp -- "^\\s*$" $input] && [validuser $hand]} {
        set input [getuser $hand XTRA incith:weather.location]
      }

      # log it
      putlog "${incith::weather::version}: <${nick}/${chan}> ${incith::weather::command_char}forecast $input"

      # no input given
      if {[regexp -- "^\\s*$" $input]} {
        send_output $where "Please visit http://classic.wunderground.com for more details on searching methods."
        return
      }

      # fetch the html
      array set html [fetch_html $input]

      # check for html's existence
      if {[info exists html(error)]} {
        send_output $where $html(error)
        return
      }

      # for seperate line results option
      if {${incith::weather::seperate_lines} >= 1} {
        set alternate_sep "\n"
      } else {
        set alternate_sep ${incith::weather::seperator}
      }

      # make sure we have data to send, and send it
      set reply [custom_format [array get html] "forecast" $incith::weather::forecast_format $nick]
      if {$reply == "0"} { unset reply }
      if {[info exists reply]} {
        send_output $where $reply
      } else {
        send_output $where "There was a problem while attempting to parse the data."
      }
    }


    # [astronomy_handler] : handles public & private messages for !sky
    #
    proc astronomy_handler {nick uhand hand args} {
      if {[llength $args] >= 2} { # public message
        if {${incith::weather::public_to_private} >= 1} {
          set where $nick
        } else {
          set where [lindex $args 0]
          if {[lsearch -exact [channel info $where] +weather] == -1} {
            return
          }
        }
        set chan [lindex $args 0]
        set input [lindex $args 1]
      } else {			  # private message
        set where $nick
        set chan "private"
        set input [lindex $args 0]
        if {${incith::weather::private_messages} <= 0} {
          return
        }
      }

      # flood protection
      if {[flood $nick $uhand $hand $where]} {
        return
      }

      # user defaults, user must exist as a user on the bot
      if {[lindex $input 0] == "-set"} {
        if {[validuser $hand]} { 
          setuser $hand XTRA incith:weather.location "[lrange $input 1 end]"
          send_output $nick "Default weather location set to [lrange $input 1 end]."
          return
        } else {
          send_output $nick "Sorry, your bot handle was not found.  Unable to set a default."
          return
        }
        set input [lrange $input 1 end]
      } elseif {[regexp -- "^\\s*$" $input] && [validuser $hand]} {
        set input [getuser $hand XTRA incith:weather.location]
      }

      # log it
      putlog "${incith::weather::version}: <${nick}/${chan}> ${incith::weather::command_char}sky $input"

      # no input given
      if {[regexp -- "^\\s*$" $input]} {
        send_output $where "Please visit http://classic.wunderground.com for more details on searching methods."
        return
      }

      # fetch the html
      array set html [fetch_html $input]

      # check for html's existence
      if {[info exists html(error)]} {
        send_output $where $html(error)
        return
      }

      # for seperate line results option
      if {${incith::weather::seperate_lines} >= 1} {
        set alternate_sep "\n"
      } else {
        set alternate_sep ${incith::weather::seperator}
      }
      # make sure we have data to send, and send it
      if {[info exists html(location)]} {
        if {$::incith::weather::usenicks > 0 } {
          set reply "\002$nick's\002 sky request${incith::weather::seperator}"
        } else {
          set reply ""
        }
        append reply "[ibold "$html(location) Astronomy"]"
        if {[info exists html(sun_rise)] && [info exists html(sun_set)]} {
          append reply "${incith::weather::seperator}[ibold "Sunrise:"] $html(sun_rise)${incith::weather::seperator}[ibold "Sunset:"] $html(sun_set)"
        }
        if {[info exists html(moon_rise)] && [info exists html(moon_set)]} {
          if {[info exists html(moon_phase)] && [info exists html(moon_percent)]} {
            append reply "${incith::weather::seperator}[ibold "Moon:"] $html(moon_phase) ($html(moon_percent))"
          }
          append reply "${incith::weather::seperator}[ibold "Moonrise:"] $html(moon_rise)"
          append reply "${incith::weather::seperator}[ibold "Moonset:"] $html(moon_set)"
        }
        if {[info exists html(length_light)]} {
          append reply "${incith::weather::seperator}[ibold "Visible Light:"] $html(length_light)"
        }
        if {[info exists html(length_day)]} {
          append reply "${incith::weather::seperator}[ibold "Daylight Length:"] $html(length_day)"
        }
        if {[info exists html(length_tomorrow)]} {
          append reply "${incith::weather::seperator}[ibold "Tomorrow:"] $html(length_tomorrow)"
        }
        send_output $where $reply
      } else {
        send_output $where "There was a problem while attempting to parse the data."
      }
    }


    # [fetch_html] : fetches and returns a list of usable data
    #
    proc fetch_html {query {query_url "http://classic.wunderground.com/cgi-bin/findweather/getForecast?query="} {no_format 0}} {
      set multiple_results 0
      # store the website we are retrieving
      set output(query) $query
      if {$no_format != 1} {
        set output(query) [::http::formatQuery $query]
        set output(query) [string trimleft $output(query) "+"]
      }

      # setup proxy information, if any
      if {[string match {*:*} ${incith::weather::proxy}] == 1} {
        set proxy_info [split ${incith::weather::proxy} ":"]
      }
      # the "browser" we are using
      set ua "Lynx/2.8.5rel.1 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/0.9.7e"
      if {[info exists proxy_info] == 1} {
        set http [::http::config -useragent $ua -proxyhost [lindex $proxy_info 0] -proxyport [lindex $proxy_info 1]]
      } else {
        set http [::http::config -useragent $ua]
      }
      # retrieve the html; round()'ed because -timeout likes integers. [catch] for error messages
      catch {set http [::http::geturl "${query_url}$output(query)" -headers {Cookie "Units=both"} -timeout [expr round(1000 * ${incith::weather::timeout})]]} output(status)

      # make sure the http request succeeded
      if {![string match {::http::*} $output(status)]} {
        set output(error) "Failed to connect."
      } elseif {[::http::status $http] == "timeout"} {
        set output(error) "The operation timed out after ${incith::weather::timeout} seconds."
      } elseif {[::http::status $http] != "ok"} {
        set output(error) "The server could not complete our request (server error)."
      }
      # in case we're erroring out, close the socket and report why
      if {[info exists output(error)]} {
        ::http::cleanup $http
        return [array get output]
      }

      # $html will contain our html source code
      set html [::http::data $http]
      # we no longer require the connection
      ::http::cleanup $http

      # debug: output the html to a file
      if {${incith::weather::debug} >= 1} {
        set fopen [open incith-weather-pre.txt w]
        puts $fopen $html
        close $fopen
      }

      if {[regexp {Search Results} $html] || [regexp {Scroll down to view a list of all all cities} $html]} {
        set multiple_results 1
      }

      # html cleanups
      regsub -all {\n} $html {} html
      regsub -all {\t} $html {} html
      regsub -all {&nbsp;} $html { } html
      regsub -all {&#176;} $html {} html
      regsub -all {&gt;} $html {>} html
      regsub -all {&lt;} $html {<} html
      regsub -all {<td style="padding: 0;">.*?</td>} $html {} html
      regsub -all {<td title="Add This Location to Your Favorite Cities"><a href="/php/editfavs\.php\?addfav=[\d\w]+\.[\d\w]+"><img src="http://icons-..\.wxug\.com/graphics/wu2/favsBarSave\.png" width="48" height="13" alt="Add to My Favorites" /></a></td>} $html {} html
 
      # debug: output the html to a file
      if {${incith::weather::debug} >= 1} {
        set fopen [open incith-weather-post.txt w]
        puts $fopen $html
        close $fopen
      }

      # check for problems
      set multiple 0
      if {[regexp {<h1>There has been an error!</h1>} $html]} {
        regexp -- {</h1>.*?<p id.*?>(.*?)<p class="b">} $html - preparse
        regsub {</p>} $preparse ". " preparse
        regsub -all -- {<.*?>} $preparse "" preparse
        set output(error) $preparse
      } elseif {[regexp {Redirect page<br><br>There is nothing} $html] || [regexp {Choose the first letter of a city or search for any location.</p>} $html] || [regexp {<h1>Europe</h1><div id="titleBar">Choose a Country</div>} $html] || [regexp {<h1>Australia</h1><div id="titleBar">Select a country or Australian province below.</div>} $html] || [regexp {<h1>Africa</h1><div id="titleBar">Choose a Country</div>} $html]} {
        set multiple_results 0
        set output(error) "Please refine your search."
      } elseif {$multiple_results == 1} {
        # todo: store bad results too in case duplicate results both have no data
        # e.g., first bad result put to bad_list, second matching bad result put to good list
        set i 1; set multiple 2; set num_results 0
        set loop_reply ""; set loop_loc ""; set loop_url ""
        # skip down a bit in the html
        regsub -- {.*?Search Results} $html {} html
        regsub -- {.*?Scroll down to view a list of all all cities} $html {} html
        # this regexp removes locations with no data
        foreach {junk row} [regexp -inline -all -- {<tr>(.*?)</tr>} $html] {
          if {![string match "*</td><td> </td><td> </td><td> </td><td> </td><td> </td>*" $row]} {
            if {[regexp -- {<tr><td><a href="(.*?\.html)">(.*?)</a></td><td>  <span} $junk - loop_url loop_loc]} {
              lappend lr $loop_loc
              lappend lu $loop_url
            }
          }
        }
        # if after filtering we only have 1 result, use it
        if {[llength [set lr [lsort -unique -increasing $lr]]] == 1} {
          unset output
          array set output [fetch_html "[lindex $lu 0]" "http://classic.wunderground.com" 1]
        } else {
          set output(error) "Multiple Results Found: [join $lr "; "]"
        }
      }

      # bail out if there's a problem
      if {[info exists output(error)]} {
        return [array get output]
      }

      # html parsing
      #
      # conditions
      regexp -- {Local Time:<span class="b">(.+? A?P?M)\s+(.+?)( on (.+?))?</span>} $html - output(local_time) output(local_timezone) output(local_date) output(local_date)
      regexp -- {Updated: <span.*? value="\d+">(.+? A?P?M)\s+(.+?) on (.+?)</span>(?:</div>|</span>)} $html - output(update_time) output(update_timezone) output(update_date)
      if {![info exists output(update_time)]} {
        regexp -- {Updated: (.+? A?P?M)\s+(.+?)( on (.+?))?</td>} $html - output(update_time) output(update_timezone) output(update_date) output(update_date)
      }
      # multiple location parses just in case
      regexp -- {id="cityTable"><tr><td class="nobr full"><h1>(.+?)\ ?</h1></td>} $html - output(location)
      if {![info exists output(location)]} {
        regexp -- {<link rel="alternate" type="application/rss\+xml" title="(.+?)\ ?RSS" href=} $html - output(location)
      }
      if {![info exists output(location)]} {
        regexp -- {<div class="subG b">(.+?)(?:\ \(Airport\)|\(PWS\))?</div>} $html - output(location)
      }
      #regexp -- {pwsvariable="tempf".+?>  <span class="nobr"><span class="b">(.+?)</span> F</span>  /  <span class="nobr"><span class="b">(.+?)</span> C</span></span></div>} $html - output(tempf) output(tempc)
      if {[regexp -nocase {<span class="nobr"><span class="b">(.*?)</span>(.*?)</span>} $html - output(tempf) output(tempc)]} {
        set output(tempc) [string index $output(tempc) end]
        if {[string equal "F" $output(tempc)]} {
          set output(tempc) [format "%.${incith::weather::granularity}f" [expr {5.0/9.0*($output(tempf) - 32.0)}]]
          if {[string match *\.* $output(tempc)]} {
		set c [split $output(tempc) .]
		set ot1 [lindex $c 0]
		set ot2 [string trim [lindex $c 1] " 0"]
		if {[string length $ot2]} { set output(tempc) "${ot1}.${ot2}" } { set output(tempc) $ot1 }
          }
        } else {
          set output(tempc) $output(tempf)
          set output(tempf) [format "%.${incith::weather::granularity}f" [expr {9.0/5.0*$output(tempc) + 32.0}]]
          if {[string match *\.* $output(tempf)]} {
		set c [split $output(tempf) .]
		set ot1 [lindex $c 0]
		set ot2 [string trim [lindex $c 1] " 0"]
		if {[string length $ot2]} { set output(tempf) "${ot1}.${ot2}" } { set output(tempf) $ot1 }
          }
        }
      }
      if {[info exists output(tempf)]} {
        set templength [string length $output(tempf)]
        if {$templength > 20} {
          putlog "length fubar"
          set output(error) "Something is fubar! :)"
          return [array get output]
        }
      }
      regexp -- {Windchill:</td>.*?<span class="nobr"><span class="b">(.*?)</span>.*?<span class="nobr"><span class="b">(.+?)</span>} $html - output(windchillf) output(windchillc)
      regexp -- {pwsvariable="humidity" english="" metric="" value="(.+?)">} $html - output(humidity)
      if {[regexp -- {pwsvariable="dewptf".+?>.*?<span class="nobr"><span class="b">(.*?)</span>(.*?)</span>} $html - output(dewf) output(dewc)]} {
        set output(dewc) [string index $output(dewc) end]
        if {[string equal "F" $output(dewc)]} {
          set output(dewc) [format "%.${incith::weather::granularity}f" [expr {5.0/9.0*($output(dewf) - 32.0)}]]
          if {[string match *\.* $output(dewc)]} {
		set c [split $output(dewc) .]
		set od1 [lindex $c 0]
		set od2 [string trim [lindex $c 1] " 0"]
		if {[string length $od2]} { set output(dewc) "${od1}.${od2}" } { set output(dewc) $od1 }
          } 
        } else {
          set output(dewc) $output(dewf)
          set output(dewf) [format "%.${incith::weather::granularity}f" [expr {9.0/5.0*$output(dewc) + 32.0}]]
          if {[string match *\.* $output(dewf)]} {
	      set c [split $output(dewf) .]
		set od1 [lindex $c 0]
		set od2 [string trim [lindex $c 1] " 0"]
		if {[string length $od2]} { set output(dewf) "${od1}.${od2}" } { set output(dewf) $od1 } 
          }
        }
      }
      # normal wind:
      regexp -- {Wind:</td>.+? pwsvariable="windspeedmph" english="mph" metric="km/h">  <span class="nobr"><span class="b">(.+?)</span> mph</span>  /  <span class="nobr"><span class="b">(.+?)</span> km/h</span>} $html - output(windm) output(windk)
      # wind direction..
      regexp -- {from the </span>.+? pwsvariable="winddir" english="" metric="" value="(.+?)">} $html - output(windd)
      # calm wind direction:
      if {![info exists output(windd)]} {
        regexp -- {Wind:</td>.+? pwsvariable="windspeedmph" english="mph" metric="km/h">(Calm)</span>} $html - output(windd)
      }

      # since adding 'from the </span>.+? ' to the above RE, if it fails, the wind should be Calm
      # removing 'from the </span>.+? ' causes it to fetch wind dir data from the wrong location
      # moved snippet of code below mobile fetch

      regexp -- {<div class="b" style="font-size: 14px;">(.+?)</div>} $html - output(conditions)
      regexp -- {<td>UV:</td><td class="b">(.+?) <span class="nb">out of (.+?)</span></td>} $html - output(uv_min) output(uv_max)
      # parse only the pressure block
      regexp -- {pwsvariable="baromin" english="in" metric="hPa" value=".*?">(.*?)</span></td>} $html - output(pressure_data)
      if {[info exists output(pressure_data)]} {
        regexp -- {<b>(.+?)</b> in  /  <b>(.+?)</b> hPa} $output(pressure_data) - output(pressure_in) output(pressure_hpa)
      }
      # lat/lon
      regexp -- {Lat/Lon: <span class="b">(\d+\.?\d+?\ \w)\ (\d+\.?\d+?\ \w)</span>} $html - output(latitude) output(longitude)
      if {[info exists output(latitude)] && [info exists output(longitude)]} {
        regsub -- "\ " $output(latitude) ${incith::weather::degree_symbol} output(latitude)
        regsub -- "\ " $output(longitude) ${incith::weather::degree_symbol} output(longitude)
      }

      # astronomy sunrise/set and moonrise/set data
      regexp -- {<td>Actual Time</td><td>(.*?)</td><td>(.*?)</td></tr>} $html - output(sun_rise) output(sun_set)
      if {[info exists output(sun_rise)]} {
        if {$output(sun_rise) == ""} {
          set output(sun_rise) "Unavailable"
        }
      }
      if {[info exists output(sun_set)]} {
        if {$output(sun_set) == ""} {
          set output(sun_set) "Unavailable"
        }
      }
      if {![info exists output(sun_rise)]} {
        set output(sun_rise) "Unavailable"
      }
      if {![info exists output(sun_set)]} {
        set output(sun_set) "Unavailable"
      }
      regexp -- {<td>Moon</td><td>(.+?)</td><td>(.*?)</td></tr>} $html - output(moon_rise) output(moon_set)
      regexp -- {<td>Length Of Visible Light:</td><td colspan="2">(.+?)</td></tr><tr><td>Length of Day</td><td colspan="2"><div>(.+?)</div><div>Tomorrow will be <span.*?">(.+?)</span>} $html - output(length_light) output(length_day) output(length_tomorrow)
      regexp -- {<td colspan="3"><div class="b">(.+?)\, (\d+\%) of the Moon is Illuminated</div>} $html - output(moon_phase) output(moon_percent)
      # some locations have spaces, some don't
      if {[info exists output(moon_rise)] && [info exists output(moon_set)]} {
        set output(moon_rise) [string trim $output(moon_rise)]
        set output(moon_set) [string trim $output(moon_set)]
      }

      # forecast
      # skip down to the actual forecast data
      regsub -- {.*?5-Day Forecast} $html {} html

      # fixes for % chance of precipitation
      regsub -all -- {Chance of T-storms} $html {Chance of Thunderstorms} html
      regsub -all -- {Chance of a Thunderstorm} $html {Chance of Thunderstorms} html
      regsub -all -- {T-storms} $html {Chance of Thunderstorms} html
      regsub -all -- {alt="Thunderstorm"} $html {alt="Chance of Thunderstorms"} html

      set fc_regexp_day {<td class="taC" style="width: 20%;">(.+?)</td>}
      set fc_regexp_cond {<div><img src=".+?\.gif" alt="(.+?)" width="\d\d" height="\d\d" class="condIcon" /></div>}
      set fc_regexp_highlow {<div class="b nobr"><span style="color: #900;">(.+?)&deg; F</span><span style="font-weight: normal; color: #999;">\|</span><span style="color: #009;">(.+?)&deg; F</span><br />.*?&deg; C.*?&deg; C.*?</div>}

      regexp -- "${fc_regexp_day}" $html - output(fc1d)
      regsub -- $fc_regexp_day $html {} html
      regexp -- "${fc_regexp_day}" $html - output(fc2d)
      regsub -- $fc_regexp_day $html {} html
      regexp -- "${fc_regexp_day}" $html - output(fc3d)
      regsub -- $fc_regexp_day $html {} html
      regexp -- "${fc_regexp_day}" $html - output(fc4d)
      regsub -- $fc_regexp_day $html {} html
      regexp -- "${fc_regexp_day}" $html - output(fc5d)
      regsub -- $fc_regexp_day $html {} html

      regexp -- "${fc_regexp_cond}" $html - output(fc1c)
      regsub -- $fc_regexp_cond $html {} html
      regexp -- "${fc_regexp_cond}" $html - output(fc2c)
      regsub -- $fc_regexp_cond $html {} html
      regexp -- "${fc_regexp_cond}" $html - output(fc3c)
      regsub -- $fc_regexp_cond $html {} html
      regexp -- "${fc_regexp_cond}" $html - output(fc4c)
      regsub -- $fc_regexp_cond $html {} html
      regexp -- "${fc_regexp_cond}" $html - output(fc5c)
      regsub -- $fc_regexp_cond $html {} html

      # chance of precipitation
      if {[info exists output(fc1c)]} {
        set fc_re_chance "<td class=\"taC\"\\ ?>$output(fc1c)<div><span class=\"b green\">(\\d+\\%)</span> chance of precipitation</div></td>"
        regexp $fc_re_chance $html - output(fc1chance)
        regsub $fc_re_chance $html {} html
      }
      if {[info exists output(fc2c)]} {
        set fc_re_chance "<td class=\"taC\"\\ ?>$output(fc2c)<div><span class=\"b green\">(\\d+\\%)</span> chance of precipitation</div></td>"
        regexp $fc_re_chance $html - output(fc2chance)
        regsub $fc_re_chance $html {} html
      }
      if {[info exists output(fc3c)]} {
        set fc_re_chance "<td class=\"taC\"\\ ?>$output(fc3c)<div><span class=\"b green\">(\\d+\\%)</span> chance of precipitation</div></td>"
        regexp $fc_re_chance $html - output(fc3chance)
        regsub $fc_re_chance $html {} html
      }
      if {[info exists output(fc4c)]} {
        set fc_re_chance "<td class=\"taC\"\\ ?>$output(fc4c)<div><span class=\"b green\">(\\d+\\%)</span> chance of precipitation</div></td>"
        regexp $fc_re_chance $html - output(fc4chance)
        regsub $fc_re_chance $html {} html
      }
      if {[info exists output(fc5c)]} {
        set fc_re_chance "<td class=\"taC\"\\ ?>$output(fc5c)<div><span class=\"b green\">(\\d+\\%)</span> chance of precipitation</div></td>"
        regexp $fc_re_chance $html - output(fc5chance)
        regsub $fc_re_chance $html {} html
      }

      regexp -- "${fc_regexp_highlow}" $html - output(fc1hf) output(fc1lf)
      regsub -- $fc_regexp_highlow $html {} html
      regexp -- "${fc_regexp_highlow}" $html - output(fc2hf) output(fc2lf)
      regsub -- $fc_regexp_highlow $html {} html
      regexp -- "${fc_regexp_highlow}" $html - output(fc3hf) output(fc3lf)
      regsub -- $fc_regexp_highlow $html {} html
      regexp -- "${fc_regexp_highlow}" $html - output(fc4hf) output(fc4lf)
      regsub -- $fc_regexp_highlow $html {} html
      regexp -- "${fc_regexp_highlow}" $html - output(fc5hf) output(fc5lf)
      regsub -- $fc_regexp_highlow $html {} html

      # debug stuff
      if {${incith::weather::debug} >= 1} {
        send_putlog "output(fc1d):" $output(fc1d)
        send_putlog "output(fc1c):" $output(fc1c)
        send_putlog "output(fc1hf):" $output(fc1hf)
        send_putlog "output(fc1lf):" $output(fc1lf)
      }

      # use mobile data if we are missing some things
      if {$multiple <= 1} {
        if {![info exists output(fc1c)] || ![info exists output(fc1d)] || ![info exists output(fc1hf)] || ![info exists output(update_time)] || ![info exists output(tempf)] || ![info exists output(windd)]} {
          if {$incith::weather::debug >= 1} {
            set mobtmperror "pulling mobile data"
            if {![info exists output(fc1c)]} {
              append mobtmperror ", missing fc1c"
            }
            if {![info exists output(fc1d)]} {
              append mobtmperror ", missing fc1d"
            }
            if {![info exists output(fc1hf)]} {
              append mobtmperror ", missing fc1hf"
            }
            if {![info exists output(update_time)]} {
              append mobtmperror ", missing update_time"
            }
            if {![info exists output(tempf)]} {
              append mobtmperror ", missing tempf"
            }
            if {![info exists output(windd)]} {
              append mobtmperror ", missing windd"
            }
            putlog $mobtmperror
          }
          array set output [fetch_mobile_html $output(query) [array get output]]
          # mobile doesn't give the chance of precipitation
          if {![info exists output(fc1hf)] || ![info exists output(fc1d)]} {
            if {[info exists output(fc1chance)]} { unset output(fc1chance) }
            if {[info exists output(fc2chance)]} { unset output(fc2chance) }
            if {[info exists output(fc3chance)]} { unset output(fc3chance) }
            if {[info exists output(fc4chance)]} { unset output(fc4chance) }
            if {[info exists output(fc5chance)]} { unset output(fc5chance) }
          }
        }
      }

      # this just looks silly
      if {[info exists output(windm)] && [info exists output(windk)]} {
        if {$output(windm) == "0.0" && $output(windk) == "0.0"} {
          unset output(windm)
          unset output(windk)
        }
      }

      # set wind if we still do not have one
      if {![info exists output(windd)]} {
        set output(windd) "Calm"
      }

      # get the current day for this location, used for proper high/low display
      if {$multiple <= 1} {
        if {[info exists output(local_time)] && [info exists output(local_date)]} {
          set output(todays_day) [clock format [clock scan "$output(local_time) $output(local_date)"] -format "%A"]
        } else {
          if {[info exists output(update_time)]} {
            set output(todays_day) [clock format [clock scan "$output(update_time) $output(update_date)"] -format "%A"]
          }
        }
      }

      # convert updated time into 24 hour time if wanted
      if {${incith::weather::24hour_time} >= 1 && [info exists output(update_time)]} {
        regsub -- {^(.* (AM)?(PM)?).*?$} $output(update_time) {\1} output(update_time)
        set output(update_time) [clock format [clock scan "$output(update_time)"] -format "%H:%M"]
      }

      # this returns our 'output' array
      return [array get output]
    }


    # [fetch_mobile_html] : fetches and returns a list of usable data
    #
    proc fetch_mobile_html {query current_array} {
      array set foutput $current_array
      # setup proxy information, if any
      if {[string match {*:*} ${incith::weather::proxy}] == 1} {
        set proxy_info [split ${incith::weather::proxy} ":"]
      }
      # the "browser" we are using
      set ua "Lynx/2.8.5rel.1 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/0.9.7e"
      if {[info exists proxy_info] == 1} {
        set http [::http::config -useragent $ua -proxyhost [lindex $proxy_info 0] -proxyport [lindex $proxy_info 1]]
      } else {
        set http [::http::config -useragent $ua]
      }
      # retrieve the html; round()'ed because -timeout likes integers. [catch] for error messages
      catch {set http [::http::geturl "http://mobile.wunderground.com/cgi-bin/findweather/getForecast?brand=mobile&query=$query" -headers {Cookie "Units=both"} -timeout [expr round(1000 * ${incith::weather::timeout})]]} foutput(status)

      # make sure the http request succeeded
      if {![string match {::http::*} $foutput(status)]} {
        set foutput(error) "Failed to connect."
      } elseif {[::http::status $http] == "timeout"} {
        set foutput(error) "The operation timed out after ${incith::weather::timeout} seconds."
      } elseif {[::http::status $http] != "ok"} {
        set output(error) "The server could not complete our request (server error)."
      }
      # in case we're erroring out, close the socket and report why
      if {[info exists foutput(error)]} {
        ::http::cleanup $http
        return [array get foutput]
      }

      # $html will contain our html source code
      set html [::http::data $http]
      # we no longer require the connection
      ::http::cleanup $http

      # html cleanups
      regsub -all {\n} $html {} html
      regsub -all {\t} $html {} html
      regsub -all {&nbsp;} $html { } html
      regsub -all {&#176;} $html {} html
      regsub -all {&gt;} $html {>} html
      regsub -all {&lt;} $html {<} html
      regsub -all {(?:<nobr>|</nobr>)} $html {} html

      # html parsing
      #
      regexp -- {Updated: <b>(.+? A?P?M)\ ?(.+?) on (.+?)</b>} $html - output(update_time) output(update_timezone) output(update_date)
      regexp -- {Observed at\ ?<b>(.+?)</b> </td>} $html - output(location)
      regexp -- {<tr><td>Temperature</td>  <td>  <span class="nowrap"><b>(.+?)</b>F</span>  /  <span class="nowrap"><b>(.+?)</b>C</span>} $html - foutput(tempf) foutput(tempc)
      # wind
      regexp -- {<tr><td>Wind</td><td><b>(.+?)</b> at  <span class="nowrap"><b>(.+?)</b> mph</span>  /  <span class="nowrap"><b>(.+?)</b> km/h</span>} $html - foutput(windd) foutput(windm) foutput(windk)

      # forecast
      # todo: update to grab 1 by 1
      regexp -- {<b>Forecast as of (.+?) on (.+?)\ ?</b>} $html - foutput(fupdate_time) foutput(fupdate_date)
      # the Night-named days get removed, to parse the non-Night days easier
      regsub -all {<td align="left"><b>(?:Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday) Night</b><br />} $html {} html
      if {$incith::weather::debug >= 1} {
        putlog "in mobile, fc1hf = $foutput(fc1hf)\nfc1chance = $foutput(fc1chance)\n"
      }
      if {![info exists foutput(fc1d)] || ![info exists foutput(fc1hf)]} {
        if {$incith::weather::debug >= 1} {
          putlog "fetching forecast in mobile"
        }
        set fc_regexp_day {<td align="left"><b>(.+?)</b><br />  (.+?)\.High:  (.+?)&deg; F\..+?  Low:  (.+?)&deg; F\.  /  .+?</td></tr>}
        regexp -- "${fc_regexp_day}.+?${fc_regexp_day}.+?${fc_regexp_day}" $html - foutput(fc1d) foutput(fc1c) foutput(fc1hf) foutput(fc1lf) foutput(fc2d) foutput(fc2c) foutput(fc2hf) foutput(fc2lf) foutput(fc3d) foutput(fc3c) foutput(fc3hf) foutput(fc3lf)
      }

      # convert updated time into 24 hour time if wanted
      if {${incith::weather::24hour_time} >= 1 && [info exists foutput(fupdate_time)]} {
        regsub -- {^(.* (AM)?(PM)?).*?$} $foutput(fupdate_time) {\1} foutput(fupdate_time)
        set foutput(fupdate_time) [clock format [clock scan "$foutput(fupdate_time)"] -format "%H:%M"]
      }

      # this returns our 'foutput' array
      return [array get foutput]
    }


    # [send_output] : sends $data appropriately out to $where
    #
    proc send_output {where data} {
      if {${incith::weather::notices} >= 1 && ![string match {#*} $where]} {
        foreach line [incith::weather::parse_output $data] {
          putserv "NOTICE $where :${line}"
        }
      } else {
        foreach line [incith::weather::parse_output $data] {
          putserv "PRIVMSG $where :${line}"
        }
      }
    }

    # [send_putlog] : sends $data appropriately out to putlog
    #
    proc send_putlog {prefix {data ""}} {
      if {![info exists data]} {
        foreach line [incith::weather::parse_output $prefix] {
          putlog "${line}"
        }
      } else {
        foreach line [incith::weather::parse_output $data] {
          putlog "${prefix} ${line}"
        }
      }
    }

    # [parse_output] : prepares output for sending to a channel/user, calls line_wrap
    #
    proc parse_output {input} {
      set parsed_output [set parsed_current {}]
      if {[string match "\n" $incith::weather::seperator] == 1 || ${incith::weather::seperate_lines} >= 1} {
        regsub {\n\s*$} $input "" input
        foreach newline [split $input "\n"] {
          foreach line [incith::weather::line_wrap $newline] {
            lappend parsed_output $line
          }
        }
      } else {
        #regsub "(?:${incith::weather::seperator}|\\|)\\s*$" $input {} input
        foreach line [incith::weather::line_wrap $input] {
          lappend parsed_output $line
        }
      }
      return $parsed_output
    }

    # LINE_WRAP
    # takes a long line in, and chops it before the specified length
    # http://forum.egghelp.org/viewtopic.php?t=6690
    #
    proc line_wrap {str {splitChr { }}} {
      set out [set cur {}]
      set i 0
      set len $incith::weather::split_length
      foreach word [split [set str][set str ""] $splitChr] {
        if {[incr i [string len $word]] > $len} {
          lappend out [join $cur $splitChr]
          set cur [list $word]
          set i [string len $word]
        } else {
          lappend cur $word
        }
        incr i
      }
      lappend out [join $cur $splitChr]
    }

    # [ibold] : bolds some text, if bolding is enabled
    #
    proc ibold {input} {
      if {${incith::weather::bold} >= 1} {
        return "\002${input}\002"
      }
      return $input
    }

    # [i2fac] : display only 2 temperatures
    #
    proc i2fac {f c} {
      if {${incith::weather::celcius_first} >= 1} {
        return "${c}${incith::weather::degree_symbol}C (${f}${incith::weather::degree_symbol}F)"
      } else {
        return "${f}${incith::weather::degree_symbol}F (${c}${incith::weather::degree_symbol}C)"
      }
    }

    # [ifac] : helper proc for forecast-type temperatures & conversion procs
    #
    proc ifac {fh fl ch cl} {
      if {${incith::weather::celcius_first} >= 1} {
        return "${ch}/${cl}${incith::weather::degree_symbol}C (${fh}/${fl}${incith::weather::degree_symbol}F)"
      } else {
        return "${fh}/${fl}${incith::weather::degree_symbol}F (${ch}/${cl}${incith::weather::degree_symbol}C)"
      }
    }

    # IF2C
    # converts fahrenheit to celcius & returns a formatted string
    #
    proc if2c {fh fl} {
      set ch [format "%.${incith::weather::granularity}f" [expr {(5.0/9.0)*($fh - 32.0)}]]
      if {[string match *\.* $ch]} {
		set c [split $ch .]
		set ch1 [lindex $c 0]
		set ch2 [string trim [lindex $c 1] " 0"]
		if {[string length $ch2]} { set ch "${ch1}.${ch2}" } { set ch $ch1 }
      } 
      set cl [format "%.${incith::weather::granularity}f" [expr {(5.0/9.0)*($fl - 32.0)}]]
	if {[string match *\.* $cl]} {
		set c [split $cl .]
		set cl1 [lindex $c 0]
		set cl2 [string trim [lindex $c 1] " 0"]
		if {[string length $cl2]} { set cl "${cl1}.${cl2}" } { set cl $cl1 }
      } 
      return [ifac $fh $fl $ch $cl]
    }

    # IC2F
    # converts celcius to fahrenheit & returns a formatted string
    #
    proc ic2f {ch cl} {
      set fh [format "%.${incith::weather::granularity}f" [expr {(9.0/5.0)*$ch + 32.0}]]
      if {[string match *\.* $fh]} {
		set c [split $fh .]
		set fh1 [lindex $c 0]
		set fh2 [string trim [lindex $c 1] " 0"]
		if {[string length $fh2]} { set fh "${fh1}.${fh2}" } { set fh $fh1 }
      } 
      set fl [format "%.${incith::weather::granularity}f" [expr {(9.0/5.0)*$cl + 32.0}]]
      if {[string match *\.* $fl]} {
		set c [split $fl .]
		set fl1 [lindex $c 0]
		set fl2 [string trim [lindex $c 1] " 0"]
		if {[string length $fl2]} { set cl "${fl1}.${fl2}" } { set fl $fl1 }
      }
      return [ifac $fh $fl $ch $cl]
    }

    # FLOOD_INIT
    # modified from bseen
    #
    variable flood_data
    variable flood_array
    proc flood_init {} {
      if {$incith::weather::ignore < 1} {
        return 0
      }
      if {![string match *:* $incith::weather::flood]} {
        putlog "${incith::weather::version}: variable flood not set correctly."
        return 1
      }
      set incith::weather::flood_data(flood_num) [lindex [split $incith::weather::flood :] 0]
      set incith::weather::flood_data(flood_time) [lindex [split $incith::weather::flood :] 1]
      set i [expr $incith::weather::flood_data(flood_num) - 1]
      while {$i >= 0} {
        set incith::weather::flood_array($i) 0
        incr i -1
      }
    }
    ; flood_init

    # FLOOD
    # updates and returns a users flood status
    #
    proc flood {nick uhand hand where} {
      # exempt friends
      if {[matchattr $hand "f|f" $where]} {
        return 0
      }

      if {$incith::weather::ignore < 1} {
        return 0
      }
      if {$incith::weather::flood_data(flood_num) == 0} {
        return 0
      }
      set i [expr ${incith::weather::flood_data(flood_num)} - 1]
      while {$i >= 1} {
        set incith::weather::flood_array($i) $incith::weather::flood_array([expr $i - 1])
        incr i -1
      }
      set incith::weather::flood_array(0) [unixtime]
      if {[expr [unixtime] - $incith::weather::flood_array([expr ${incith::weather::flood_data(flood_num)} - 1])] <= ${incith::weather::flood_data(flood_time)}} {
        putlog "${incith::weather::version}: flood detected from ${nick}."
        putserv "notice $nick :$incith::weather::version: flood detected, placing you on ignore for $::incith::weather::ignore minute(s)! :P"
        newignore [join [maskhost *!*[string trimleft $uhand ~]]] $incith::weather::version flooding $incith::weather::ignore
        return 1
      } else {
        return 0
      }
    }
  }
}

# the script has loaded.
putlog " - ${incith::weather::version} loaded."

# EOF
