#!/usr/bin/env lci

OBTW, this is a Whitespace interpreter written in LOLCODE. Nobody quite knows
why this happened, but it's pretty great all the same. I know, I know... TLDR

HAI 1.4

CAN HAS STDIO?
CAN HAS STRING?

OBTW, LOLCODE provides ample support for associative arrays, but we're gonna
need sequential ones too. The following "class" provides the infrastructure
we'll need for the instruction list, the call stack, and the Whitespace stack.
Arrays grow dynamically as they're pushed into, and that's quite nice. TLDR
I HAS AN ARRAY ITZ A BUKKIT

OBTW, arrays are initialized with a capacity of 1 and a dummy entry to permit
growth by a factor of 2. We (ab)use the SRS operator for numeric indices. TLDR
HOW IZ ARRAY FORMED BTW, how girl get pragnent
    I HAS AN ary ITZ A BUKKIT
    ary HAS A size ITZ 0
    ary HAS A capa ITZ 1
    ary HAS A SRS 0

    FOUND YR ary
IF U SAY SO

OBTW, there's no way to determine whether a particular slot is occupied and
re-initializing (with HAS A) is verboten, so we pre-initialize the new elements
(to NOOB, the undefined value) and set them to real values later (with R). TLDR
HOW IZ ARRAY GROWIN YR ary
    I HAS A size ITZ ary'Z size

    IM IN YR grower UPPIN YR i TIL BOTH SAEM i AN size
        ary HAS A SRS SUM OF size AN i
    IM OUTTA YR grower

    ary'Z capa R SUM OF size AN size
IF U SAY SO

BTW, index into the array with its size to add a new element.
HOW IZ ARRAY PUSHIN YR ary AN YR elem
    I HAS A size ITZ ary'Z size

    BOTH SAEM size AN ary'Z capa, O RLY?
        YA RLY, ARRAY IZ GROWIN YR ary MKAY
    OIC

    ary'Z SRS size R elem
    ary'Z size R SUM OF size AN 1
IF U SAY SO

OBTW, decrement the array's size such that the next push overwrites
the old value, that being what this function returns. TLDR
HOW IZ ARRAY POPPIN YR ary
    ary'Z size R DIFF OF ary'Z size AN 1

    FOUND YR ary'Z SRS ary'Z size
IF U SAY SO

OBTW, let's build some lookup tables for mapping between ASCII characters and
their ordinal values so that `getchar` and `putchar` are reasonably fast. TLDR

I HAS A CHRS ITZ A BUKKIT
I HAS A ORDS ITZ A BUKKIT

HOW IZ I HEXIN YR num
    I HAS A hex ITZ ""
    I HAS A alpha ITZ "0123456789ABCDEF"

    IM IN YR hexalizer
        hex R SMOOSH STRING IZ AT YR alpha AN YR MOD OF num AN 16 MKAY hex MKAY
        num R QUOSHUNT OF num AN 16

        NOT num, O RLY?
            YA RLY, FOUND YR hex
        OIC
    IM OUTTA YR hexalizer
IF U SAY SO

IM IN YR tables UPPIN YR ord TIL BOTH SAEM ord AN 128
    I HAS A chr ITZ SMOOSH "::(" I IZ HEXIN YR ord MKAY ")" MKAY
    CHRS HAS A SRS ord ITZ chr
    ORDS HAS A SRS chr ITZ ord
IM OUTTA YR tables

OBTW, a token is one of space, tab, or newline; all other characters are ignored
as comments. Regrettably, there's an lci bug that prevents escape sequences from
being interpreted correctly when used as case labels, so we convert to S, T, and
N such that we can use switch statements in what is already a messy parser. TLDR
HOW IZ I TOKENIZIN YR program
    I HAS A len ITZ STRING IZ LEN YR program MKAY
    I HAS A tokens ITZ ARRAY IZ FORMED MKAY
    I HAS A char

    IM IN YR tokenizer UPPIN YR i TIL BOTH SAEM i AN len
        char R STRING IZ AT YR program AN YR i MKAY

        ORDS'Z SRS char, WTF?
        OMG  9, ARRAY IZ PUSHIN YR tokens AN YR "T" MKAY, GTFO
        OMG 10, ARRAY IZ PUSHIN YR tokens AN YR "N" MKAY, GTFO
        OMG 32, ARRAY IZ PUSHIN YR tokens AN YR "S" MKAY, GTFO
        OIC
    IM OUTTA YR tokenizer

    FOUND YR tokens
IF U SAY SO

OBTW, this is just so that we can process the tokens from the back of the array.
Much better than shifting the entire thing over when we remove an elemnt. TLDR
HOW IZ STRING REVERSIN YR str
    I HAS A rev ITZ ""
    I HAS A len ITZ STRING IZ LEN YR str MKAY

    IM IN YR reverser UPPIN YR i TIL BOTH SAEM i AN len
        rev R SMOOSH STRING IZ AT YR str AN YR i MKAY AN rev MKAY
    IM OUTTA YR reverser

    FOUND YR rev
IF U SAY SO

BTW, this is where we build instruction nodes.
HOW IZ I BILDIN YR op
    O HAI IM insn
        I HAS A op ITZ op
        I HAS A arg ITZ ""

        op, WTF?
        OMG "push", OMG "copy", OMG "call", OMG "slide",
        OMG "jump", OMG "jmpz", OMG "jmpn", OMG "label"
        arg R I IZ ARGUIN MKAY
        OIC
    KTHX

    FOUND YR insn
IF U SAY SO

BTW, consume an argument from the token stream.
HOW IZ I ARGUIN
    I HAS A arg ITZ 0
    I HAS A sign ITZ ARRAY IZ POPPIN YR tokens MKAY

    IM IN YR consumer
        ARRAY IZ POPPIN YR tokens MKAY, WTF?
        OMG "T", arg R SUM OF arg AN 1, GTFO
        OMG "N"
            BOTH SAEM sign AN "T", O RLY?
                YA RLY, arg R DIFF OF 0 AN arg
            OIC
            FOUND YR QUOSHUNT OF arg AN 2
        OIC

        arg R PRODUKT OF arg AN 2
    IM OUTTA YR consumer
IF U SAY SO

OBTW, consume one or two tokens at a time and branch accordingly. This might
be the hardest lci's switch statement support has ever been exercised. TLDR
HOW IZ I PARSIN YR program
    I HAS A op
    I HAS A insn
    I HAS A insns ITZ ARRAY IZ FORMED MKAY

    IM IN YR parser UPPIN YR i WILE tokens'Z size
        ARRAY IZ POPPIN YR tokens MKAY, WTF?
        OMG "S"
            ARRAY IZ POPPIN YR tokens MKAY, WTF?
            OMG "S", op R "push", GTFO
            OMG "T"
                ARRAY IZ POPPIN YR tokens MKAY, WTF?
                OMG "S", op R "copy", GTFO
                OMG "N", op R "slide", GTFO
                OIC, GTFO
            OMG "N"
                ARRAY IZ POPPIN YR tokens MKAY, WTF?
                OMG "S", op R "dup", GTFO
                OMG "T", op R "swap", GTFO
                OMG "N", op R "pop", GTFO
                OIC, GTFO
            OIC, GTFO
        OMG "T"
            ARRAY IZ POPPIN YR tokens MKAY, WTF?
            OMG "S"
                SMOOSH ARRAY IZ POPPIN YR tokens MKAY...
                       ARRAY IZ POPPIN YR tokens MKAY MKAY, WTF?
                OMG "SS", op R "add", GTFO
                OMG "ST", op R "sub", GTFO
                OMG "SN", op R "mul", GTFO
                OMG "TS", op R "div", GTFO
                OMG "TT", op R "mod", GTFO
                OIC, GTFO
            OMG "T"
                ARRAY IZ POPPIN YR tokens MKAY, WTF?
                OMG "S", op R "store", GTFO
                OMG "T", op R "load", GTFO
                OIC, GTFO
            OMG "N"
                SMOOSH ARRAY IZ POPPIN YR tokens MKAY...
                       ARRAY IZ POPPIN YR tokens MKAY MKAY, WTF?
                OMG "SS", op R "putchar", GTFO
                OMG "ST", op R "putnum", GTFO
                OMG "TS", op R "getchar", GTFO
                OMG "TT", op R "getnum", GTFO
                OIC, GTFO
            OIC, GTFO
        OMG "N"
            SMOOSH ARRAY IZ POPPIN YR tokens MKAY...
                   ARRAY IZ POPPIN YR tokens MKAY MKAY, WTF?
            OMG "SS", op R "label", GTFO
            OMG "ST", op R "call", GTFO
            OMG "SN", op R "jump", GTFO
            OMG "TS", op R "jmpz", GTFO
            OMG "TT", op R "jmpn", GTFO
            OMG "TN", op R "return", GTFO
            OMG "NN", op R "exit", GTFO
            OIC, GTFO
        OIC

        BTW, if nothing matched, we've got ourselves a syntax error.
        NOT op, O RLY?
            YA RLY, FOUND YR FAIL
        OIC

        insn R I IZ BILDIN YR op MKAY
        ARRAY IZ PUSHIN YR insns AN YR insn MKAY

        OBTW, pre-compute jump targets for efficiency and to permit jumping
        to an as yet unseen label. Also, keep them in the instruction stream
        so that the indices line up correctly but otherwise ignore them. TLDR
        BOTH SAEM op AN "label", O RLY?
            YA RLY, jumps HAS A SRS insn'Z arg ITZ i
        OIC

        op R NOOB
    IM OUTTA YR parser

    FOUND YR insns
IF U SAY SO

OBTW, the heap maintains an ARRAY of its keys such that we can determine
whether to assign to a new slot (with HAS A) or overwrite an old one (with R).
This is an unfortunate oversight in the LOLCODE spec by my lights. TLDR
HOW IZ I STORIN YR key AN YR val
    IM IN YR finder UPPIN YR i TIL BOTH SAEM i AN heap'Z keys'Z size
        BOTH SAEM heap'Z keys'Z SRS i AN key, O RLY?
            YA RLY, heap'Z SRS key R val, FOUND YR WIN
        OIC
    IM OUTTA YR finder

    heap HAS A SRS key ITZ val
    ARRAY IZ PUSHIN YR heap'Z keys AN YR key MKAY
IF U SAY SO

BTW, put it all together. It's all pretty straightforward from here.
HOW IZ I EXECUTIN YR insns
    I HAS A stack ITZ ARRAY IZ FORMED MKAY
    I HAS A calls ITZ ARRAY IZ FORMED MKAY
    I HAS A insn, I HAS A op, I HAS A arg

    IM IN YR Exeggcutor UPPIN YR i TIL BOTH SAEM i AN insns'Z size
        insn R insns'Z SRS i
        op R insn'Z op
        arg R insn'Z arg

        BOTH SAEM op AN "exit", O RLY?
            YA RLY, GTFO
        OIC

        op, WTF?
        BTW, stack stuff
        OMG "push"
            ARRAY IZ PUSHIN YR stack AN YR arg MKAY, GTFO
        OMG "pop"
            ARRAY IZ POPPIN YR stack MKAY, GTFO
        OMG "dup"
            I HAS A peek ITZ stack'Z SRS DIFF OF stack'Z size AN 1
            ARRAY IZ PUSHIN YR stack AN YR peek MKAY, GTFO
        OMG "swap"
            I HAS A a ITZ ARRAY IZ POPPIN YR stack MKAY
            I HAS A b ITZ ARRAY IZ POPPIN YR stack MKAY
            ARRAY IZ PUSHIN YR stack AN YR a MKAY
            ARRAY IZ PUSHIN YR stack AN YR b MKAY, GTFO
        OMG "copy"
            I HAS A peek ITZ stack'Z SRS DIFF OF DIFF OF stack'Z size 1 arg
            ARRAY IZ PUSHIN YR stack AN YR peek MKAY, GTFO
        OMG "slide"
            I HAS A top ITZ ARRAY IZ POPPIN YR stack MKAY
            IM IN YR slider UPPIN YR i TIL BOTH SAEM i AN arg
                ARRAY IZ POPPIN YR stack MKAY
            IM OUTTA YR slider
            ARRAY IZ PUSHIN YR stack AN YR top MKAY, GTFO

        BTW, I/O
        OMG "getchar"
            I HAS A key ITZ ARRAY IZ POPPIN YR stack MKAY
            I HAS A ord ITZ ORDS'Z SRS STDIO IZ LUK YR stdin AN YR 1 MKAY
            NOT ord, O RLY?
                YA RLY, ord R -1
            OIC
            I IZ STORIN YR key AN YR ord MKAY, GTFO
        OMG "getnum"
            I HAS A key ITZ ARRAY IZ POPPIN YR stack MKAY
            I HAS A num, GIMMEH num
            I IZ STORIN YR key AN YR MAEK num A NUMBR MKAY, GTFO
        OMG "putchar"
            VISIBLE CHRS'Z SRS ARRAY IZ POPPIN YR stack MKAY!, GTFO
        OMG "putnum"
            VISIBLE ARRAY IZ POPPIN YR stack MKAY!, GTFO

        BTW, jumps and whatnot
        OMG "call"
            ARRAY IZ PUSHIN YR calls AN YR i MKAY BTW, fall through for lulz
        OMG "jump"
            i R jumps'Z SRS arg, GTFO
        OMG "jmpz"
            NOT ARRAY IZ POPPIN YR stack MKAY, O RLY?
                YA RLY, i R jumps'Z SRS arg
            OIC, GTFO
        OMG "jmpn"
            DIFFRINT 0 AN SMALLR OF 0 AN ARRAY IZ POPPIN YR stack MKAY, O RLY?
                YA RLY, i R jumps'Z SRS arg
            OIC, GTFO 
        OMG "return"
            i R ARRAY IZ POPPIN YR calls MKAY, GTFO

        BTW, arithmetic
        OMG "add", OMG "sub", OMG "mul", OMG "div", OMG "mod"
            I HAS A b ITZ ARRAY IZ POPPIN YR stack MKAY
            I HAS A a ITZ ARRAY IZ POPPIN YR stack MKAY
            op, WTF?
            OMG "add", arg R SUM OF a AN b, GTFO
            OMG "sub", arg R DIFF OF a AN b, GTFO
            OMG "mul", arg R PRODUKT OF a AN b, GTFO
            OMG "div", arg R QUOSHUNT OF a AN b, GTFO
            OMG "mod", arg R MOD OF a AN b, GTFO
            OIC
            ARRAY IZ PUSHIN YR stack AN YR arg MKAY, GTFO

        BTW, heap stuff
        OMG "store"
            I HAS A val ITZ ARRAY IZ POPPIN YR stack MKAY
            I HAS A key ITZ ARRAY IZ POPPIN YR stack MKAY
            I IZ STORIN YR key AN YR val MKAY, GTFO
        OMG "load"
            I HAS A val ITZ heap'Z SRS ARRAY IZ POPPIN YR stack MKAY
            ARRAY IZ PUSHIN YR stack AN YR val MKAY, GTFO
        OIC
    IM OUTTA YR Exeggcutor

    FOUND YR stack'Z size
IF U SAY SO

OBTW, the SMOOSH operator (used here to build up the contents of a file a
kilobyte at a time) interprets escape sequences like `:)`, which is maybe
a bug in lci. Escaping them would require building a new string with the
colons doubled up (`::::`), except the only way to build up a string is
with the SMOOSH operator, so those two colons would again become one.
I set out to write a Whitespace interpreter, not a quine, so let's hope
we don't receive any "literate" programs containing `:>` or `:)`. TLDR
HOW IZ I READIN YR filename
    I HAS A bufsize ITZ 1024
    I HAS A fd ITZ STDIO IZ OPEN YR filename AN YR "r" MKAY

    STDIO IZ DIAF YR fd MKAY, O RLY?
        YA RLY, FOUND YR FAIL
    OIC

    I HAS A contents ITZ ""
    I HAS A chunk

    IM IN YR reader
        chunk R STDIO IZ LUK YR fd AN YR bufsize MKAY
        NOT chunk, O RLY?
            YA RLY, FOUND YR contents
        OIC
        contents R SMOOSH contents AN chunk MKAY
    IM OUTTA YR reader
IF U SAY SO

OBTW, we cater to the lowest common denominator and take a filename as input.
On Linux, we could read /proc/self/cmdline to get access to the command-line
arguments, but who knows how the fuck they do it in Windows land. It'd be nifty
if lci exposed this information out of the box. :< I wanted to add various and
sundry switches for debugging and whatnot, but alas. TLDR
I HAS A filename
VISIBLE "CAN HAS filename? "!, GIMMEH filename
I HAS A program ITZ I IZ READIN YR filename MKAY

OBTW, here's hoping this works on Windows. I couldn't be arsed to take the
sure-fire approach of consuming standard input a line at a time and keeping
track of where we're at in the buffer and whether we need another line. TLDR
I HAS A stdin ITZ STDIO IZ OPEN YR "/dev/stdin" AN YR "r" MKAY

program, O RLY?
    YA RLY
        program R STRING IZ REVERSIN YR program MKAY

        BTW, these are globals. Don't tell anyone.
        I HAS A tokens ITZ I IZ TOKENIZIN YR program MKAY
        I HAS A jumps ITZ A BUKKIT
        I HAS A insns ITZ I IZ PARSIN YR tokens MKAY

        BOTH SAEM insns AN FAIL, O RLY?
            YA RLY
                INVISIBLE "U HAS A syntax error ITZ INVISIBLE"
            NO WAI
                I HAS A heap ITZ A BUKKIT
                heap HAS A keys ITZ ARRAY IZ FORMED MKAY

                OBTW, print some debug information so people feel bad about
                not cleaning up after themselves before terminating. TLDR
                I HAS A ss ITZ I IZ EXECUTIN YR insns MKAY
                I HAS A hs ITZ heap'Z keys'Z size
                INVISIBLE "Stack size: :{ss}:)Heap size: :{hs}"
        OIC
    NO WAI
        INVISIBLE "':{filename}' CANT HAS EXISTENZ"
OIC

KTHXBYE
