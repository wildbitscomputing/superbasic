# mdelta

Gets the current delta status of the PS/2 mouse. 6 reference parameters
(normally integer variables) are provided: cumulative mouse changes in the x, y,
z axes, and the number of times the left, middle and right buttons have been
pressed.

```basic
100   mdelta dx,dy,dz,lmb,mmb,rmb
```
