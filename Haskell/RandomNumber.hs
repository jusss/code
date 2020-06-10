import System.Random
main = do
     x <- newStdGen
     print $ randomR (0:: Int,999999:: Int) x
