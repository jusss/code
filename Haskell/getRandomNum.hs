import System.Random
import System.Random.Shuffle

-- _find :: [a] -> [(a,b)] -> [[a]]
_find str keyPair = fmap (f keyPair) str
     where
        f k c = fmap (\(x,y) -> if x == c then y else 0) k



_match str keyPair =
     sum $ _find str keyPair >>= (return . sum)



genKeyPair seed = zipWith (,) (['a'..'z'] <> ['A'..'Z'] <> ['0'..'9'] <> ['_']) $ shuffle' [1..63] 63 (mkStdGen seed)

keyPair = genKeyPair 42


main = print $ _match "aha" keyPair
