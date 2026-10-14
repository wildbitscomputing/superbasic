10 rem Construct exact represented PI/2 without division rounding.
20 a#=pi:poke @a#+4,peek(@a#+4)-1
30 print tan(a#)
40 print "UNEXPECTED SUCCESS"
