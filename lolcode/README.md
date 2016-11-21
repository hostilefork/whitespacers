### WTF?
This is a Whitespace interpreter written in LOLCODE.

### WHY?
For science and teh lulz.

### HOW DUZ I RUN IT?
The intepreter has only been tested and confirmed operational with [lci's future branch](https://github.com/justinmeza/lci/tree/future). You're a `git clone -b future https://github.com/justinmeza/lci` away from having your own copy.

Included in this directory are a brainfuck interpreter written in Whitespace and a brainfuck implementation of ROT13 cribbed from Wikipedia. LOLCODE doesn't support command-line arguments, so the file to be executed is accepted on standard input. Thus, the *pièce de résistance* (C interpreting LOLCODE interpreting Whitespace interpreting brainfuck) is a little underwhelming:

    lci whitespace.lol < rot13.b

This takes a while to run (lots of agonizingly slow heap accesses), so there's also a FizzBuzz for demonstrating to the impatient that the thing does what it should. Oh, and a syntax-highlighted screenshot because pretty; I should get around to writing a Pygments lexer at some point.
