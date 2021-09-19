import Control.Monad.Trans.Cont
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import System.IO

-- main = flip runContT return $ do
--     lift $ print "hi"
--     lift $ print "there"

-- it would be withFile "inFile.txt" ReadMode $ \inHandle ->
--                  withFile "outFile.txt" WriteMode $ \outHandle ->
--                      copy inHandle outHandle
copyFile :: ContT r IO ()
copyFile = do
      inHandle <- ContT $ withFile "inFile.txt" ReadMode
      outHandle <- ContT $ withFile "outFile.txt" WriteMode
      lift (copy inHandle outHandle)

copy h1 h2 = do
    str <- hGetContents h1
    hPutStr h2 str

main = runContT copyFile return


