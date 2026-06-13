import re 

sources = """
./aa.main/aa.data.asm
./aa.main/_vectors.asm
./aa.main/main.asm
./drawing/circle.asm
./drawing/mode.asm
./drawing/sprite.asm
./drawing/clear.asm
./drawing/control.asm
./drawing/rect.asm
./drawing/sources/sprite.asm
./drawing/sources/font.asm
./drawing/plot.asm
./drawing/render.asm
./drawing/line.asm
./utility/calculate.asm
./utility/collide.asm
./utility/access.asm
./utility/sort.asm
./utility/find.asm
""".strip().split("\n")

labels = """
GSCurrentSpriteAddr
GSCurrentSpriteID
gsOffset
gxAcquireVector
gxAddSelect
gxAdjust
gxANDValue
gxBasePage
gxBitmapsOn
gxCentre
gxColour
gxCurrentX
gxCurrentY
gxDiffX
gxDiffY
gxDXNegative
gxEORValue
gxHeight
gxIsDiffYLarger
gxIsFillMode
gxLastX
gxLastY
gxMask
gxMode
gxOriginalLUTValue
gxPosition
gxRadius
gxScale
gxSize
gxSizeBits 			
gxSizePixels 			
gxSpriteHigh		
gxSpriteLow
gxSpriteLUT 								
gxSpriteOffset 							
gxSpriteOffsetBase
gxSpritePage
gxSpritesOn
gxTotal		
gxUseMode
gxX0
gxX1
gxY0
gxY1
gxYChanged
gYCentre
""".strip().split("\n")

#
convert = {}
for l in [x.strip() for x in labels if x.strip() != ""]:
	target = l 
	if l.startswith("gs"):
		target = "gx"+l[2:]
	if l.endswith("Centre"):
		target = "gx"+l[1:]
	assert l.lower() not in convert
	convert[l.lower()] = target
#
test = [x for x in convert.keys()]

for f in sources:
	print(f)
	h = open(f)
	source = [x.rstrip() for x in h.readlines()]
	h.close()
	for i in range(0,len(source)):
		l = source[i]
		for t in test:
			l = re.sub(t, convert[t], l, flags=re.IGNORECASE)
		source[i] = l
	h = open(f,"w")
	h.write("\n".join(source))
	h.close()