10 rem Native radian trigonometry regression tests
20 assert abs(pi-3.1415927)<0.000001
30 assert sin(0)=0:assert cos(0)=1:assert tan(0)=0
40 assert abs(sin(pi/2)-1)<0.000001
50 assert abs(sin(pi))<0.000001:assert abs(sin(2*pi))<0.000001
60 assert abs(cos(pi/2))<0.000001:assert abs(cos(-pi/2))<0.000001
70 assert abs(cos(pi)+1)<0.000001
80 assert abs(tan(pi/4)-1)<0.000001
90 assert abs(tan(-pi/4)+1)<0.000001
100 assert abs(sin(cos(0))-sin(1))<0.000001
110 assert abs(7+2*sin(0.5)-7.9588511)<0.000001
120 x#=123:t#=456:r#=789:a#=sin(0.0349)
130 assert x#=123:assert t#=456:assert r#=789
140 z#=0.00001*0.00001:z#=z#*z#
150 assert sin(z#)>0:assert sin(z#)<1:assert sin(z#)=z#
160 assert sin(-z#)<0:assert sin(-z#)=-z#
170 assert cos(z#)=1:assert tan(z#)>0:assert tan(z#)<1
180 print "TINY AND NESTED PASS"
190 for i=-100 to 100
200 a#=i*0.071
210 assert abs(sin(a#)*sin(a#)+cos(a#)*cos(a#)-1)<0.000002
220 assert abs(sin(-a#)+sin(a#))<0.000002
230 assert abs(cos(-a#)-cos(a#))<0.000002
240 next
250 print "IDENTITIES PASS"
260 assert abs(sin(-1000)-(-0.82687954))<0.000002
270 assert abs(cos(-1000)-(0.56237908))<0.000002
280 assert abs(tan(-1000)-(-1.4703242))<0.000002
290 assert abs(sin(-235)-(-0.58058664))<0.000002
300 assert abs(cos(-235)-(-0.81419847))<0.000002
310 assert abs(tan(-235)-(0.71307754))<0.000002
320 assert abs(sin(-100)-(0.50636564))<0.000002
330 assert abs(cos(-100)-(0.86231887))<0.000002
340 assert abs(tan(-100)-(0.58721392))<0.000002
350 assert abs(sin(-7)-(-0.65698660))<0.000002
360 assert abs(cos(-7)-(0.75390225))<0.000002
370 assert abs(tan(-7)-(-0.87144798))<0.000002
380 assert abs(sin(-3.142)-(0.00040734))<0.000002
390 assert abs(cos(-3.142)-(-0.99999992))<0.000002
400 assert abs(tan(-3.142)-(-0.00040734))<0.000002
410 assert abs(sin(-1.57)-(-0.99999968))<0.000002
420 assert abs(cos(-1.57)-(0.00079632))<0.000002
430 assert abs(tan(-1.57)-(-1255.7656))<0.01
440 assert abs(sin(-0.0349)-(-0.03489291))<0.000002
450 assert abs(cos(-0.0349)-(0.99939106))<0.000002
460 assert abs(tan(-0.0349)-(-0.03491417))<0.000002
470 assert abs(sin(0.00001)-(0.00001000))<0.000002
480 assert abs(cos(0.00001)-(1.0000000))<0.000002
490 assert abs(tan(0.00001)-(0.00001000))<0.000002
500 assert abs(sin(0.0349)-(0.03489291))<0.000002
510 assert abs(cos(0.0349)-(0.99939106))<0.000002
520 assert abs(tan(0.0349)-(0.03491417))<0.000002
530 assert abs(sin(0.7)-(0.64421769))<0.000002
540 assert abs(cos(0.7)-(0.76484219))<0.000002
550 assert abs(tan(0.7)-(0.84228838))<0.000002
560 assert abs(sin(1)-(0.84147098))<0.000002
570 assert abs(cos(1)-(0.54030231))<0.000002
580 assert abs(tan(1)-(1.5574077))<0.000002
590 assert abs(sin(1.57)-(0.99999968))<0.000002
600 assert abs(cos(1.57)-(0.00079632))<0.000002
610 assert abs(tan(1.57)-(1255.7656))<0.01
620 assert abs(sin(3.142)-(-0.00040734))<0.000002
630 assert abs(cos(3.142)-(-0.99999992))<0.000002
640 assert abs(tan(3.142)-(0.00040734))<0.000002
650 assert abs(sin(7)-(0.65698660))<0.000002
660 assert abs(cos(7)-(0.75390225))<0.000002
670 assert abs(tan(7)-(0.87144798))<0.000002
680 assert abs(sin(100)-(-0.50636564))<0.000002
690 assert abs(cos(100)-(0.86231887))<0.000002
700 assert abs(tan(100)-(-0.58721392))<0.000002
710 assert abs(sin(235)-(0.58058664))<0.000002
720 assert abs(cos(235)-(-0.81419847))<0.000002
730 assert abs(tan(235)-(-0.71307754))<0.000002
740 assert abs(sin(1000)-(0.82687954))<0.000002
750 assert abs(cos(1000)-(0.56237908))<0.000002
760 assert abs(tan(1000)-(1.4703242))<0.000002
770 assert abs(sin(identity(0.5))-0.47942554)<0.000001
780 z#=z#*0.000000001:z#=z#/2
790 assert sin(z#)>0:assert sin(z#)<1:assert sin(z#)=z#
800 assert cos(z#)=1:assert tan(z#)>0:assert tan(z#)<1
810 h#=1000000/1:h#=h#*h#:h#=h#*h#
820 assert abs(sin(h#))<=1:assert abs(cos(h#))<=1
830 assert abs(sin(-h#)+sin(h#))<0.000001
840 assert abs(cos(-h#)-cos(h#))<0.000001
850 print "TRIG PASS"
860 end
900 fn identity(a#)
910 return a#
920 endfn
