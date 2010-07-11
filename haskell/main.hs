{-
**********************************************************************
     Whitespace - A language with no visible syntax.
     Copyright (C) 2003 Edwin Brady (e.c.brady@durham.ac.uk)
     
     This program is free software; you can redistribute it and/or
     modify it under the terms of the GNU General Public License
     as published by the Free Software Foundation; either version 2
     of the License, or (at your option) any later version.
     
     This program is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU General Public License for more details.
     
     You should have received a copy of the GNU General Public License along
     with this program; if not, write to the Free Software Foundation, Inc.,
     59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.

**********************************************************************
-}

module Main where

import Input
import VM
import Tokens

import System(getArgs)

main :: IO ()
main = do
       args <- getArgs
       if (length args)/=1
        then usage
	else execute (head args)

usage :: IO ()
usage = do
	putStrLn "wspace 0.2 (c) 2003 Edwin Brady"
	putStrLn "-------------------------------"
	putStrLn "Usage: wspace [file]"

