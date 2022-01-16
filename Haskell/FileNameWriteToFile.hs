import System.Directory
import Control.Monad
import System.Environment

main = do
    fileList <- getDirectoryContents "/tmp"
    traverse print fileList
    writeFile "/tmp/test.html" " "
    traverse (\x -> appendFile "/tmp/test.html" $ x <> "\n") fileList
