import Control.Monad.Cont
import Control.Monad.Writer

type Processed = [Double]
type Result = [Double]

rec :: [Double] -> ContT Processed (Writer Result) Processed
rec xs = mapK p xs
  where
    p x c = if x == 0
        then c x
        else lift (tell [1/x]) >> c (1/x)

    mapK :: (Double -> (Double -> ContT Processed (Writer Result) Processed) -> ContT Processed (Writer Result) Processed)
         -> [Double]
         -> ContT Processed (Writer Result) Processed
    mapK _ [] = return []
    mapK p (x:xs) = p x $ \v -> do
        vs <- mapK p xs
        return (v : vs)

main :: IO ()
main = do
    let (processed, result) = runWriter $ runContT (rec [1,2,3,0,4]) return
    print processed
    print result
