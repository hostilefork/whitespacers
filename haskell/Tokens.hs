module Tokens where

data Token = A | B | C 
  deriving Eq
instance Show Token where
    show A = " "
    show B = "\t"
    show C = "\n"
