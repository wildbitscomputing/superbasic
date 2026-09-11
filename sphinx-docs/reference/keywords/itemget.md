# {kwd}`itemget$()`

Extracts the specified item from a string split using a separator. Takes three
parameters: the input string, the index of the desired item (starting from 1),
and the separator. Returns the specified sub-item. If the index is out of range,
a range error is raised. See also {kwd}`itemcount()`.

The example below prints `"lizzie"`, which is the third item in the list.

```basic
100 print itemget$("paul,jane,lizzie,jack", 3, ",")
```
