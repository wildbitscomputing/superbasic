10 assert exists("EXISTS.BAS")=true
20 assert exists("ABSENT.DAT")=false
30 assert exists("EMPTY.DAT")=true
40 assert exists("LARGE.DAT")=true
50 assert exists("SUBDIR/INNER.DAT")=true
60 assert exists("SUBDIR/ABSENT.DAT")=false
70 assert exists("subdir/inner.dat")=true
80 assert exists("MANY/LAST.DAT")=true
90 assert exists("MANY/ABSENT.DAT")=false
100 s$="EMPTY":assert 7+exists(s$+".DAT")=6
110 dim names$(2):names$(1)="EMPTY.DAT":assert exists(names$(1))
120 for i=1 to 100
130 assert exists("EMPTY.DAT"):assert not(exists("ABSENT.DAT"))
140 next
150 poke $1800,123:assert exists("LARGE.DAT"):assert peek($1800)=123
160 try bload "SUBDIR/INNER.DAT",$1800 to ec:assert ec=0
170 assert peek($1800)=65
180 assert exists("/EMPTY.DAT")
190 try bsave "SAVED.DAT",$1800,1 to ec:assert ec=0:assert exists("SAVED.DAT")
200 print "EXISTS PASS"
