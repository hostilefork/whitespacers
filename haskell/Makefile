GHC = ghc
GHCI = ghci

SRCS = main.hs Input.hs VM.hs Tokens.hs
OBJS = main.o Input.o VM.o Tokens.o
OPTS = -O -fvia-C

TARGET = wspace

$TARGET: ${OBJS}
	${GHC} ${OPTS} ${OBJS} -o ${TARGET}

ghci: 
	${GHCI} ${OPTS} main.hs

depend:
	ghc -M ${OPTS} ${SRCS}

clean:
	rm -f ${TARGET} ${OBJS}
	rm -f *~ *.hi

%.o: %.hs
	${GHC} -c ${OPTS} $< -o $@

%.hi: %.o
	@:

# DO NOT DELETE: Beginning of Haskell dependencies
main.o : main.hs
main.o : ./Tokens.hi
main.o : ./VM.hi
main.o : ./Input.hi
Input.o : Input.hs
Input.o : ./Tokens.hi
Input.o : ./VM.hi
VM.o : VM.hs
Tokens.o : Tokens.hs
# DO NOT DELETE: End of Haskell dependencies
