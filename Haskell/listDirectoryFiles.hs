import System.Directory
import Control.Monad

main = do
    fileList <- getDirectoryContents "/tmp"
    traverse print fileList
