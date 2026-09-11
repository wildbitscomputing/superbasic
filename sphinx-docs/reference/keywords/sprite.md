# {kwd}`sprite`

Manipulate one of the 64 hardware sprites using the standard modifiers. Also
supported are `sprite image <n>` which turns a sprite on and selects image \<n>
to be used for it, and `sprite off`, which turns a sprite off. Sprite data is
stored at `$30000` onwards. Sprites cannot be scaled and flipped as the hardware
does not permit it. Sprites have their own section. For `sprite .. to` the
sprite is centred on those coordinates.

```basic
100 sprite 4 image 2 to 50,200
```
