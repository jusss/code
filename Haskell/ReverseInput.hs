-- module ReverseInput where, comment this line will link to a binary file via `ghc --make ReverseInput.hs', uncomment this line will not compile to a binary file, it will be used as a module file

import Control.Monad
import Data.Char
import System.IO

main = do
     -- turn off line buffer
     hSetBuffering stdout NoBuffering
     putStr "Give me some input: "
     l <- getLine
     if null l
        then return ()
        else do
                -- putStrLn $ map toUpper l        
                putStrLn $ reverse l
                main
    
-- main = do
--      -- turn off line buffer
--      hSetBuffering stdout NoBuffering
--      putStr "Give me some input: "
--      l <- getLine
--      -- putStrLn $ map toUpper l        
--      putStrLn $ reverse l
--      when (not (null l)) main

