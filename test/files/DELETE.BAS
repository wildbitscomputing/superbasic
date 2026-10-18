10 poke $1800,65
20 bsave "REMOVE.DAT",$1800,1
30 delete "REMOVE.DAT"
40 try bload "REMOVE.DAT",$1800 to ec:assert ec<>0
50 try delete "REMOVE.DAT" to ec:assert ec<>0
60 try delete "SUBDIR" to ec:assert ec<>0
70 try bload "SUBDIR/INNER.DAT",$1800 to ec:assert ec=0:assert peek($1800)=65
80 dim files$(2):files$(1)="SUBDIR/TEMP.DAT"
90 bsave files$(1),$1800,1:try delete files$(1) to ec:assert ec=0
100 for i=1 to 100
110 try bsave "TEMP.DAT",$1800,1 to ec:assert ec=0
120 try delete "TEMP.DAT" to ec:assert ec=0
130 next
140 bsave "ROOT.DAT",$1800,1:delete "/ROOT.DAT"
150 try bload "EMPTY.DAT",$1800 to ec:assert ec=0
160 try delete "LOCKED.DAT" to ec:assert ec<>0
170 try bload "LOCKED.DAT",$1800 to ec:assert ec=0
180 bload "CROSS.DAT",$29FF0
190 bsave "COPY.DAT",$29FF0,9000
200 delete "CROSS.DAT"
210 drive 255:try delete "EMPTY.DAT" to ec:assert ec<>0:drive 0
220 print "DELETE PASS"
