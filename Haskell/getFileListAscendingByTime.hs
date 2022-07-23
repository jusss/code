import System.Directory
import Data.List

listDirectoryAscendingByTime :: String -> IO ()
listDirectoryAscendingByTime path = do
    filelist <- listDirectory path
    tl <- traverse getModificationTime $ (path <>) <$> filelist
    let fl = reverse $ fst <$> (sortOn snd $ zipWith (,) filelist tl)
    print $ fl

main = listDirectoryAscendingByTime "Downloads/"
