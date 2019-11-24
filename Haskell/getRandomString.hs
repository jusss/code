import System.Random
import Data.Tuple
import System.Environment

randomSequence :: RandomGen g => [a] -> g -> Int -> [a] -> [a]
randomSequence = \l g count result ->
               if count > 0 then
                  let s = (randomR (0, length l - 1) g) in
                             randomSequence l  (snd s)  (count - 1) $ ((!!) l $ fst s) : result
               else
                  result

l = "abcdefghijklmnopqrstuvwxyz0123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZ"

getRandomString _number randomNumber = randomSequence l (mkStdGen randomNumber) _number ""

main = do
  args <- getArgs
  let i = read $ head args :: Int
  let ii = read $ head $ tail args :: Int
  putStrLn $ getRandomString i ii

-- ./getRandomString 22 111111111111111111112222222222222222222222222222222218888888888888888866666666666666
