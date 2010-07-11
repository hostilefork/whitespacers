module Input where

import VM
import Tokens

{- Input to the whitespace VM.
   For convenience, three input characters 
       A => space, B => tab, C => either of CR/LF

Numbers are binary (A=0, B=1, C=terminator)
Strings are sequences of binary characters, terminated by C.

We have:

* Stack instructions (Preceded by A)
     Push (Integer)    A
     Dup           CA
     Swap          CB
     Discard       CC

* Arithmetic (Preceded by BA)
     Plus          AA
     Minus         AB
     Times         AC
     Divide        BA
     Modulo        BB

* Heap access (Preceded by BB)
     Store         A
     Retrieve      B

* Control     (Preceded by C)
     Label String  AA
     Call Label    AB
     Jump Label    AC
     If Zero Label BA
     If Neg Label  BB
     Return        BC
     End           CC

* IO instructions (Preceded by BC)
     OutputChar    AA
     OutputNum     AB
     ReadChar      BA
     ReadNum       BB

-}

execute :: String -> IO ()
execute fname = do
   prog <- readFile fname
   let tokens = tokenise prog
   let runtime = parse tokens
   vm (VM runtime (Stack []) (Stack []) [] 0)

tokenise :: String -> [Token]
tokenise [] = []
tokenise (x:xs) | [x] == show A = A:(tokenise xs)
		| [x] == show B = B:(tokenise xs)
		| [x] == show C = C:(tokenise xs)
		| otherwise = tokenise xs

parse :: [Token] -> Program
parse [] = []
parse (A:A:xs) = let (num,rest) = parseNumber xs in
		  (Push num):(parse rest)
parse (A:C:A:xs) = Dup:(parse xs)
parse (A:B:A:xs) = let (num,rest) = parseNumber xs in
		   (Ref num):(parse rest)
parse (A:B:C:xs) = let (num,rest) = parseNumber xs in
		   (Slide num):(parse rest)
parse (A:C:B:xs) = Swap:(parse xs)
parse (A:C:C:xs) = Discard:(parse xs)

parse (B:A:A:A:xs) = (Infix Plus):(parse xs)
parse (B:A:A:B:xs) = (Infix Minus):(parse xs)
parse (B:A:A:C:xs) = (Infix Times):(parse xs)
parse (B:A:B:A:xs) = (Infix Divide):(parse xs)
parse (B:A:B:B:xs) = (Infix Modulo):(parse xs)

parse (B:B:A:xs) = Store:(parse xs)
parse (B:B:B:xs) = Retrieve:(parse xs)

parse (C:A:A:xs) = let (string,rest) = parseString xs in
		    (Label string):(parse rest)
parse (C:A:B:xs) = let (string,rest) = parseString xs in
		    (Call string):(parse rest)
parse (C:A:C:xs) = let (string,rest) = parseString xs in
		    (Jump string):(parse rest)
parse (C:B:A:xs) = let (string,rest) = parseString xs in
		    (If Zero string):(parse rest)
parse (C:B:B:xs) = let (string,rest) = parseString xs in
		    (If Negative string):(parse rest)

parse (C:B:C:xs) = Return:(parse xs)
parse (C:C:C:xs) = End:(parse xs)

parse (B:C:A:A:xs) = OutputChar:(parse xs)
parse (B:C:A:B:xs) = OutputNum:(parse xs)
parse (B:C:B:A:xs) = ReadChar:(parse xs)
parse (B:C:B:B:xs) = ReadNum:(parse xs)

parse _ = error "Unrecognised input"

parseNumber :: Num x => [Token] -> (x, [Token])
parseNumber ts = parseNum' ts []
  where
    parseNum' (C:rest) acc = (makeNumber acc,rest)
    parseNum' (x:rest) acc = parseNum' rest (x:acc)

parseString :: [Token] -> (String, [Token])
parseString ts = parseStr' ts []
  where
    parseStr' (C:rest) acc = (makeString acc,rest)
    parseStr' (x:rest) acc = parseStr' rest (x:acc)

makeNumber :: Num x => [Token] -> x
makeNumber t
   | (last t) == A = makeNumber' (init t) 1
   | otherwise = -(makeNumber' (init t) 1)
  where
     makeNumber' [] pow = 0
     makeNumber' (A:rest) pow = (makeNumber' rest (pow*2))
     makeNumber' (B:rest) pow = pow + (makeNumber' rest (pow*2))

makeString :: [Token] -> String
makeString [] = ""
makeString (t:ts) = (show t)++(makeString ts)
{-
    let fst = take 8 ts in
    let rest = drop 8 ts in
    (toEnum (makeNumber fst)):(makeString rest) -}