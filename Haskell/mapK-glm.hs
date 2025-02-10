import Control.Monad.State
import Control.Monad

-- The State monad is used to simulate the side effect of appending to a list.
type ResultState = State [Double]

-- The mapK function in the State monad.
mapK :: (a -> ResultState b) -> [a] -> (b -> ResultState c) -> ResultState c
mapK p ls k = foldl (>=>) (k []) (map p ls)

-- The function to handle the recursive call.
rec :: (Num a, Fractional a) => [a] -> ResultState [a]
rec ls = mapK f ls return
  where
    f x = if x == 0 then return [x] else do
      modify (1/x:)
      return [1/x]

-- The main function that executes the State and prints the results.
main :: IO ()
main = do
  (output, result') <- runStateT (rec [1,2,3,0,4]) []
  putStrLn $ show output
  putStrLn $ show result'
