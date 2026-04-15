# *******************************************************************************************
# *******************************************************************************************
#
# Name : 		tokens.py
# Purpose :	Raw token data
# Date :		18th September 2022
# Author : 	Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

import re

# *******************************************************************************************
#
# Raw token source class
#
# *******************************************************************************************


class TokenSource(object):
    def get(self):
        return """
			{+}							// Shift up
				while
				if
				repeat
				for
				proc
				fn
			{-} 						// Shift down
				wend
				endfn
				endif
				then
				until
				next
				endproc
			{u} 						// Unary functions
				abs( 		asc( 		chr$( 		alloc(		frac(		len(
				left$( 		mid$( 		right$( 	rnd( 		sgn( 		int(
				spc( 		str$( 		val(  		isval(		true 		false
				not(		random(	 	timer( 		event( 		joyx(		joyy(
				joyb( 		min(		max( 		hit( 		playing(	gettime$(
				peek( 		peekw( 		peekl(		peekd(		getdate$(	inkey$(
				get$( 		inkey(		get( 		itemcount(	itemget$( 	keydown(
				tile(		screen(	    screen$(	fre(~
				cwd$(		dir$(		dir(		tab(

			{0}							// Set 0
				data 		dim 		let 		rem  		else 		to
				downto		call 		read 		local 		line 		by
				sprite 		rect		text 		circle 		here 		color
				colour 		solid 		outline 	gfx			image 		at
				from		plot 		on 			off 		palette 	sound
				poke 		pokew 		pokel 		poked 		memcopy 	clear
				step~
				name

			{1}							// Set 1
				end 		new 		list 		run 		stop
				restore 	assert 		assemble 	bitmap		sprites
				load 		go 			zap	 		ping 		setdate
				shoot 		explode 	xload 		xgo 		settime
				save		verify		drive 		dir 		bload
				bsave		lomem 		input 		cls 		gosub
				return 		print 		cprint 		goto 		cursor
				mouse 		mdelta 		try 		tile 		tiles
				option		cd

			{2}							// Set 2 (Assembler Mnemonics)
				adc	and	asl	bcc	bcs	beq	bit	bmi	bne	bpl	bra	brk	bvc	bvs
				clc	cld	cli	clv	cmp	cpx	cpy	dec	dex	dey	eor	inc	inx	iny
				jmp	jsr	lda	ldx	ldy	lsr	nop	ora	pha	php	phx	phy	pla	plp
				plx	ply	rol	ror	rti	rts	sbc	sec	sed	sei	sta	stx	sty	stz
				tax	tay	trb	tsb	tsx	txa	txs	tya stp
"""


# *******************************************************************************************
#
# Token Classes
#
# *******************************************************************************************


class Token(object):
    def __init__(self, name, set, sort_last=False):
        self.name = name.upper().strip()
        self.set = set
        self.id = None
        self.label = None
        self._sort_last = sort_last

    #
    def sortKey(self):
        prefix = "9" + str(self.set)
        if self._sort_last:
            prefix += "~"
        return prefix + self.name

    #
    def getName(self):
        return self.name

    def getSet(self):
        return self.set

    def getID(self):
        return self.id

    def getLabel(self):
        return self.label

    #
    def setID(self, id):
        self.id = id

    def setLabel(self, label):
        self.label = label


class PunctuationToken(Token):
    def __init__(self, name):
        Token.__init__(self, name, -1)
        self.precedence = 0

    def getPrecedence(self):
        return self.precedence

    def sortKey(self):
        return "P" + self.name

    def setPrecedence(self, p):
        self.precedence = p


class CtrlToken(Token):
    def sortKey(self):
        return "0" + str(self.set) + self.name


class UnaryToken(Token):
    def __init__(self, name, sort_last=False):
        Token.__init__(self, name, 0)
        self._sort_last = sort_last

    def sortKey(self):
        return ("1~" if self._sort_last else "1") + self.name


class StructureToken(Token):
    def __init__(self, name, adjust):
        Token.__init__(self, name, 0)
        self.adjustment = adjust

    def sortKey(self):
        return ("2" if self.adjustment > 0 else "3") + self.name

    def getAdjustment(self):
        return self.adjustment


# *******************************************************************************************
#
# Token Collection
#
# *******************************************************************************************


class TokenCollection(object):
    def __init__(self):
        self.tokens = {}  # name -> object
        self.tokenList = []  # sorted list of objects
        for i in range(0, 3):
            self.addToken(
                "!0:EOF" + str(i), CtrlToken("!0:EOF", i)
            )  # add EOF/Shift tokens
            self.addToken("!1:SH1" + str(i), CtrlToken("!1:SH1", i))
            self.addToken("!2:SH2" + str(i), CtrlToken("!2:SH2", i))
        self.loadTokens()
        self.allocateIDs()  # allocate IDs.
        self.createPunctuationTokens()  # create punctuation tokens
        self.scanSource()  # look for code

    #
    # Load tokens in
    #
    def loadTokens(self):
        s = (
            TokenSource().get().upper().replace("\t", " ").split("\n")
        )  # get source into lines no tabs
        s = [x if x.find("//") < 0 else x[: x.find("//")] for x in s]  # remove comments
        cClass = "0"
        for w in " ".join(s).split():  # convert into list.
            if w.startswith("{") and w.endswith("}"):
                cClass = w[1:-1]
            else:
                if cClass == "+" or cClass == "-":  # Adjuster / structure
                    newToken = StructureToken(w, 1 if cClass == "+" else -1)
                elif cClass == "U":  # Unary function
                    sort_last = w.endswith("~")
                    if sort_last:
                        w = w[:-1]
                    newToken = UnaryToken(w, sort_last=sort_last)
                else:  # The rest
                    sort_last = w.endswith("~")
                    if sort_last:
                        w = w[:-1]
                    newToken = Token(w, int(cClass), sort_last=sort_last)
                self.addToken(w, newToken)
        self.tokenList.sort(key=lambda x: x.sortKey())  # sort into the correct order

    #
    # Create all punctuation tokens.
    #
    def createPunctuationTokens(self):
        tokens = [None] * 64  # tokens go here.
        for i in range(32, 64):  # standard
            tokens[i] = chr(i)
        for i in range(0, 2):  # double
            for j in range(0, 3):
                tokens[i * 4 + j] = "<>"[i] + "<=>"[j]
        for i in range(64, 128):
            c = chr(i).upper()
            if c < "A" or c > "Z":
                tokens[((i & 0x20) >> 2) | (i & 7) | 0x10] = c
        for i in range(0, 64):  # create all the punctuation tokens.
            newToken = PunctuationToken(
                tokens[i] if tokens[i] is not None else "!!" + str(i)
            )
            newToken.setID(i)
            newToken.setPrecedence(self.getOperatorPrecedence(newToken.getName()))
            self.addToken(newToken.getName(), newToken)

    #
    # Get operator precedence
    #
    def getOperatorPrecedence(self, op):
        prec = {
            "&": 1,
            "|": 1,
            "^": 1,
            ">": 2,
            ">=": 2,
            "<": 2,
            "<=": 2,
            "=": 2,
            "<>": 2,
            "+": 3,
            "-": 3,
            "*": 4,
            "/": 4,
            "%": 4,
            "<<": 4,
            ">>": 4,
            "\\": 4,
            "!": 5,
            "?": 5,
            "$": 5,
        }
        return prec[op] if op in prec else 0

    #
    # Add a token
    #
    def addToken(self, w, newToken):
        assert w not in self.tokens, "Duplicate token " + w  # only once
        self.tokens[w] = newToken  # set up array/dictionary
        self.tokenList.append(newToken)

    #
    # Get a token
    #
    def getToken(self, w):
        w = w.upper().strip()
        return self.tokens[w] if w in self.tokens else None

    #
    # Allocate Token IDs
    #
    def allocateIDs(self):
        self.nextFreeID = [128, 128, 128]
        for t in self.tokenList:
            s = t.getSet()
            t.setID(self.nextFreeID[s])
            self.nextFreeID[s] += 1

    #
    # Dump a token group , text
    #
    def dumpGroupText(self, set, h):
        h.write("KeywordSet{0}:\n".format(set))
        for t in self.tokenList:
            if t.getSet() == set:
                hash = sum([ord(x) for x in t.getName()]) & 0xFF
                name = "" if t.getName().startswith("!") else t.getName()
                h.write(
                    "\t.text\t{0},${1:02x},{2:16} ; ${3:02x} {4}\n".format(
                        len(name), hash, '"' + name + '"', t.getID(), t.getName()
                    )
                )
        h.write("\t.text\t$FF\n")

    #
    # Dump a token group , constants
    #
    def dumpGroupConstants(self, set, h):
        for t in self.tokenList:
            if t.getSet() == set:
                name = "" if t.getName().startswith("!") else t.getName()
                if (
                    (t.getID() >= 131 or t.getID() < 64)
                    and t.getID() != 31
                    and t.getID() != 32
                ):
                    h.write(
                        "KWD{3}_{0:32} = ${1:02x}; ${1:02x} {2}\n".format(
                            self.processName(t.getName()),
                            t.getID(),
                            t.getName(),
                            "" if set <= 0 else set,
                        )
                    )

    #
    # Dump precedence table
    #
    def dumpPrecedenceTable(self, h):
        h.write("PrecedenceLevel:\n")
        for t in self.tokenList:
            if isinstance(t, PunctuationToken):
                h.write(
                    "\t.byte\t{0:2}\t; ${1:02x} {2}\n".format(
                        t.getPrecedence(), t.getID(), t.getName()
                    )
                )

    #
    # Dump vector table
    #
    def dumpVectorTable(self, set, h):
        h.write("VectorSet{0}:\n".format(set if set >= 0 else "Punc"))
        for t in self.tokenList:
            if t.getSet() == set:
                label = t.getLabel() if t.getLabel() is not None else "SyntaxError"
                h.write(
                    "\t.word\t{0:32} ; ${1:02x} {2}\n".format(
                        label, t.getID(), t.getName()
                    )
                )

    #
    # Process Name to remove control characters if any.
    #
    def processName(self, s):
        s = (
            s.replace("!", "PLING")
            .replace("$", "DOLLAR")
            .replace(":", "COLON")
            .replace("(", "LPAREN")
        )
        s = (
            s.replace("<", "LESS")
            .replace(">", "GREATER")
            .replace("=", "EQUAL")
            .replace("\\", "BACKSLASH")
            .replace(")", "RPAREN")
        )
        s = (
            s.replace("@", "ATCH")
            .replace("[", "LSQPAREN")
            .replace("]", "RSQPAREN")
            .replace("^", "HAT")
            .replace("+", "PLUS")
        )
        s = (
            s.replace("-", "MINUS")
            .replace("*", "STAR")
            .replace("/", "SLASH")
            .replace("%", "PERCENT")
            .replace("&", "AMPERSAND")
        )
        s = (
            s.replace("?", "QMARK")
            .replace(";", "SEMICOLON")
            .replace("'", "QUOTE")
            .replace("`", "BQUOTE")
            .replace("{", "LCURLY")
        )
        s = (
            s.replace("}", "RCURLY")
            .replace("_", "UNDERSCORE")
            .replace("|", "BAR")
            .replace(",", "COMMA")
            .replace("#", "HASH")
        )
        s = (
            s.replace(".", "PERIOD")
            .replace('"', "DQUOTE")
            .replace("~", "TILDE")
            .replace(" ", "SPACE")
            .replace("", "")
        )
        # s = s.replace("","").replace("","").replace("","").replace("","").replace("","")
        return s

    #
    # Dump group info
    #
    def group0Info(self, h1):
        h1.write("KWC_EOL = $80\n")
        h1.write("KWC_SHIFT1 = $81\n")
        h1.write("KWC_SHIFT2 = $82\n")
        h1.write("KWC_STRING = $FF\n")
        h1.write("KWC_HEXCONST = $FE\n")
        lowInc = 999
        lowDec = 999
        highAdjust = 0
        lowUnary = 999
        highUnary = 0
        for t in self.tokenList:
            if t.getSet() == 0:
                if isinstance(t, UnaryToken):
                    lowUnary = min(t.getID(), lowUnary)
                    highUnary = max(t.getID(), highUnary)
                if isinstance(t, StructureToken):
                    highAdjust = max(t.getID(), highUnary)
                    lowInc = min(t.getID(), lowInc)
                    if t.getAdjustment() < 0:
                        lowDec = min(t.getID(), lowDec)
        h1.write("KWC_FIRST_STRUCTURE = ${0:02x}\n".format(lowInc))
        h1.write("KWC_FIRST_STRUCTURE_DEC = ${0:02x}\n".format(lowDec))
        h1.write("KWC_LAST_STRUCTURE = ${0:02x}\n".format(highAdjust))
        h1.write("KWC_FIRST_UNARY = ${0:02x}\n".format(lowUnary))
        h1.write("KWC_LAST_UNARY = ${0:02x}\n".format(highUnary))

    #
    # Scan source for keywords
    #
    def scanSource(self):
        h = open("_basic.asm")
        codeFiles = h.readlines()
        h.close()
        for f1 in codeFiles:
            if f1.strip() != "" and not f1.startswith(";") and f1.find("include") >= 0:
                f = f1.split('"')[1]
                for s in open(f).readlines():
                    if s.find(";;") > 0 and s.find("[") > 0:
                        m = re.match("^(.*?)\\:\\s*\\;\\;\\s*\\[(.*?)\\]", s)
                        assert m is not None, "Bad line " + m
                        word = m.group(2).strip().upper()
                        assert word in self.tokens, "Not known " + word
                        assert self.tokens[word].getLabel() is None, "Duplicate " + word
                        self.tokens[word].setLabel(m.group(1).strip())


if __name__ == "__main__":
    note = ";\n;\tThis is automatically generated.\n;\n"
    t = TokenCollection()
    h1 = open("common/generated/kwdtext.dat", "w")
    h1.write(note)
    h1.write("\t.section code\n")
    for i in range(0, 3):
        t.dumpGroupText(i, h1)
    h1.write("\t.send code\n")
    h1.close()

    h2 = open("common/generated/kwdconst.inc", "w")
    h2.write(note)
    for i in range(-1, 2):
        t.dumpGroupConstants(i, h2)
    h2.close()

    h = open("common/generated/precedence.dat", "w")
    h.write(note)
    t.dumpPrecedenceTable(h)
    h.close()

    h1 = open("common/generated/kwdconst0.inc", "w")
    h1.write(note)
    t.group0Info(h1)
    h1.close()

    h = open("common/generated/vectors.dat", "w")
    h.write(note)
    t.dumpVectorTable(-1, h)
    for i in range(0, 3):
        t.dumpVectorTable(i, h)
    h.close()
