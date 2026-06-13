10 print "Start"
20 LET k=0
25 dim m(5)
30 LET k=k+1
40 LET a=k/2*3+4-5
45 gosub 700
46 FOR l = 1 to 5
48 NEXT l
50 IF k<1000 THEN GOTO 30
70 print "End":call #FFFF
700 return