import Control.Monad
import Control.Monad.Trans.Maybe
import Control.Monad.Trans.Class   

main :: IO ()
main = do
  input <- runMaybeT inputString
  case input of
    Just p -> putStrLn p
    Nothing ->  putStrLn "Nothing"

inputString :: MaybeT IO String
inputString = lift getLine               
