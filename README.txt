This is an interactive utility for dealing with julian dates. It can
be used to convert between various date formats, find information
about specific dates, calculate time between dates, etc. Example:


$ jul-tool
Julian: 2457387.4865393518   Gregorian: 2015/12/30 23:40:36
2457387> info
Local: 12/30/2015 (2457387) 23:55:21
  UTC: 12/31/2015 (2457387) 06:55:21
Unix time: 1451519721
J2000 time: 2015.9958843828429
TLE time: 15364.99677083
Local timezone is -7 hours from GMT
Day of year: 364/365
The day of the week is Wednesday
Thirty-one days in this month
This day is not in a leap year
2457387> 


When the tool starts, it shows the current time as both Julian and
Gregorian dates. The prompt is set to the integer julian date. Enter
"?" to get a list of available commands:


2457387> ?
Usage:

info: display information
tz: set timezone offset
=tle: set from the TLE format time string [1]
tle: display as TLE format time [1]
=unix: set from unix format time [2]
unix: display as unix time
=j2000: set from astronimical J2000 format [3]
j2000: display as J2000 format [3]
=j: set julian date
=: set gregorian date as year month day, eg. "= 2015 12 30"
+: add a julian day offset to the current date/time
vxworks: display as a vxWorks gmtset command
diff: difference between register A and register B
sto: set register B from register A
today: use current date/time
swa: swap registers a and b
q: quit


[1] https://en.wikipedia.org/wiki/Two-line_element_set
[2] Note that you generally want to set the timezone to 0 first (tz 0)
[3] https://en.wikipedia.org/wiki/Epoch_(astronomy)#Julian_years_and_J2000
