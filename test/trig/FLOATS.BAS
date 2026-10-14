10 rem General float multiply: mixed types, parsing, formatting, references
20 a#=3/2:b#=5/4
30 assert a#*b#=1.875:assert -a#*b#=-1.875
40 assert a#*(-b#)=-1.875:assert (-a#)*(-b#)=1.875
50 assert a#*4=6:assert 4*a#=6
60 z#=0/1:assert a#*z#=0:assert z#*a#=0
70 assert abs(0.1*0.2-0.02)<0.00000001
80 assert abs(123.456*0.125-15.432)<0.000001
90 h#=1000000/1:h#=h#*h#:assert h#>999999999
100 assert abs(h#/1000000/1000000-1)<0.000001
110 t#=0.00001*0.00001:t#=t#*t#:assert t#>0
120 assert abs(t#/0.00001/0.00001/0.00001/0.00001-1)<0.000001
130 for i=-32 to 32
140 a#=i/8:b#=a#*1.25:s$=str$(b#)
150 assert abs(val(s$)-b#)<0.000001
160 next
170 a#=1.25:b#=1.5:c#=1.75
180 assert a#*(b#*c#)=3.28125
190 assert a#*product(b#,c#)=3.28125
200 assert a#=1.25:assert b#=1.5:assert c#=1.75
210 rem Array extends into slot 3, which the hardware routine temporarily banks
220 dim values#(200,9)
230 values#(200,9)=1.25:values#(199,9)=1.5
240 assert values#(200,9)*values#(199,9)=1.875
250 assert values#(200,9)=1.25:assert values#(199,9)=1.5
260 rem The integer-only multiply must keep its existing exact/range behaviour
270 assert 32767*32767=1073676289
280 assert 30000*30000=900000000
290 assert -12345*12345=-152399025
300 print "FLOATS PASS"
310 end
400 fn product(a#,b#)
410 return a#*b#
420 endfn
