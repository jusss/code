#!/usr/bin/env runhaskell

import Control.Monad.State

gc :: Integer -> State Integer Integer
gc x = do
  oldN <- get
  let newN = oldN + 1
  put newN
  return (x + newN)

main :: IO ()
main = do
  print (evalState (traverse gc [1,1,1]) 0)

