import System.IO
import System.Environment
import Control.Monad
main = do
     args <- getArgs
     if (null args) then
         putStrLn "it needs a file name"

     else     
          withFile (head args) ReadMode (\handle -> do
              contents <- hGetContents handle
              putStr contents)

-- ./ReadFile "/tmp/test.txt"
-- args :: IO [String]
