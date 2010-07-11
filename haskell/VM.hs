module VM where

import IO

{- Stack machine for running whitespace programs -}

data Instruction =
       Push Integer
     | Dup
     | Ref Int
     | Slide Int
     | Swap
     | Discard
     | Infix Op
     | Store
     | Retrieve
     | Label Label
     | Call Label
     | Jump Label
     | If Test Label
     | Return
     | OutputChar
     | OutputNum
     | ReadChar
     | ReadNum
     | End
   deriving (Show,Eq)

data Op = Plus | Minus | Times | Divide | Modulo
   deriving (Show,Eq)

data Test = Zero | Negative
   deriving (Show,Eq)

type Label = String
type Loc = Integer

type Program = [Instruction]
newtype Stack = Stack [Integer]
type Heap = [Integer]

data VMState = VM {
        program :: Program,
	valstack :: Stack,
	callstack :: Stack,
	memory :: Heap,
	pcounter :: Integer }

vm :: VMState -> IO ()
vm (VM prog (Stack stack) cstack heap pc) = do
  let instr = prog!!(fromInteger pc)
--  putStrLn (show stack)
  doInstr (VM prog (Stack stack) cstack heap (pc+1)) instr

-- Running individual instructions

doInstr :: VMState -> Instruction -> IO ()
doInstr (VM prog (Stack stack) cs heap pc) (Push n)
    = vm (VM prog (Stack (n:stack)) cs heap pc)
doInstr (VM prog (Stack (n:stack)) cs heap pc) Dup
    = vm (VM prog (Stack (n:n:stack)) cs heap pc)
doInstr (VM prog (Stack (stack)) cs heap pc) (Ref i)
    = vm (VM prog (Stack ((stack!!i):stack)) cs heap pc)
doInstr (VM prog (Stack (n:stack)) cs heap pc) (Slide i)
    = vm (VM prog (Stack (n:(drop i stack))) cs heap pc)
doInstr (VM prog (Stack (n:m:stack)) cs heap pc) Swap
    = vm (VM prog (Stack (m:n:stack)) cs heap pc)
doInstr (VM prog (Stack (n:stack)) cs heap pc) Discard
    = vm (VM prog (Stack stack) cs heap pc)
doInstr (VM prog (Stack (y:x:stack)) cs heap pc) (Infix op)
    = vm (VM prog (Stack ((doOp op x y):stack)) cs heap pc)
  where doOp Plus x y = x + y
	doOp Minus x y = x - y
	doOp Times x y = x * y
	doOp Divide x y = x `div` y
	doOp Modulo x y = x `mod` y
doInstr (VM prog (Stack (n:stack)) cs heap pc) OutputChar
    = do putChar (toEnum (fromInteger n))
	 hFlush stdout
	 vm (VM prog (Stack stack) cs heap pc)
doInstr (VM prog (Stack (loc:stack)) cs heap pc) ReadChar
    = do ch <- getChar
	 hp <- store (toInteger (fromEnum ch)) loc heap
	 vm (VM prog (Stack stack) cs hp pc)
doInstr (VM prog (Stack (loc:stack)) cs heap pc) ReadNum
    = do ch <- getLine
	 let num = (read ch)::Integer
	 hp <- store num loc heap
	 vm (VM prog (Stack stack) cs hp pc)	  
doInstr (VM prog (Stack (n:stack)) cs heap pc) OutputNum
    = do putStr (show n)
	 hFlush stdout
	 vm (VM prog (Stack stack) cs heap pc)
doInstr (VM prog stack cs heap pc) (Label _)
    = vm (VM prog stack cs heap pc)
doInstr (VM prog stack (Stack cs) heap pc) (Call l)
    = do loc <- findLabel l prog
	 vm (VM prog stack (Stack (pc:cs)) heap loc)
doInstr (VM prog stack cs heap pc) (Jump l)
    = do loc <- findLabel l prog
	 vm (VM prog stack cs heap loc)
doInstr (VM prog (Stack (n:stack)) cs heap pc) (If t l)
    = do if (test t n)
          then do loc <- findLabel l prog
		  vm (VM prog (Stack stack) cs heap loc)
	  else vm (VM prog (Stack stack) cs heap pc)
  where test Zero n = n==0
	test Negative n = n<0
doInstr (VM prog stack (Stack (c:cs)) heap pc) Return
    = vm (VM prog stack (Stack cs) heap c)
doInstr (VM prog (Stack (n:loc:stack)) cs heap pc) Store
    = do hp <- store n loc heap
	 vm (VM prog (Stack stack) cs hp pc)
doInstr (VM prog (Stack (loc:stack)) cs heap pc) Retrieve
    = do val <- retrieve loc heap
	 vm (VM prog (Stack (val:stack)) cs heap pc)

doInstr (VM prog (Stack stack) cs heap pc) End
       = return ()
doInstr _ i = fail $ "Can't do " ++ show i 

-- Digging out labels from wherever they are

findLabel :: Label -> Program -> IO Integer
findLabel l p = findLabel' l p 0

findLabel' l [] _ = fail $ "Undefined label (" ++ l ++ ")"
findLabel' m ((Label l):xs) i
    | l == m = return i
    | otherwise = findLabel' m xs (i+1)
findLabel' m (_:xs) i = findLabel' m xs (i+1)

-- Heap management

retrieve :: Integer -> Heap -> IO Integer
retrieve x heap = return (heap!!(fromInteger x))

store :: Integer -> Integer -> Heap -> IO Heap
store x 0 (h:hs) = return (x:hs)
store x n (h:hs) = do hp <- store x (n-1) hs
		      return (h:hp)
store x 0 [] = return (x:[])
store x n [] = do hp <- store x (n-1) [] 
		  return (0:hp)

