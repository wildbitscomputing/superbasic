# {kwd}`itemcount()`

Takes a string and a separator, and returns the number of items found by
splitting the string at each occurrence of the separator. A companion to
{kwd}`itemget$()`.

The example below prints `2`, as the string contains two items, `"hello"` and
`"world"`, separated by a comma.

```basic
100 print itemcount("hello,world", ",")
```
