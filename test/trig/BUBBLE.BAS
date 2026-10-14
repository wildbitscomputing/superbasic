100 rem Bubble Universe: radians, built-in trigonometry, one test frame
110 n=200
120 r#=pi*2/235
130 x#=0:y#=0:v#=0:t#=0
140 s=60
150 bitmap on
160 cls
210 for i=0 to n
220 for j=0 to n
230 u#=sin(i+v#)+sin(r#*i+x#)
240 v#=cos(i+v#)+cos(r#*i+x#)
250 x#=u#+t#
260 a=40+int((2+u#)*s):b=int((2-v#)*s)
270 c=2
280 if i>=100 then c=c+1
290 if j>=100 then c=c+2
300 plot colour c to a,b
310 next
320 next
330 print "BUBBLE PASS"
340 rem For animation replace line 330 with t#=t#+0.025 and add 350 goto 210
