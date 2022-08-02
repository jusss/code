import Data.List
import Control.Applicative

alist = ["a","b","c"]
blist = ["awe","bword","fc","wf","lp"]

{- get blist's element which contain alist's element -}

getSeq :: String -> String -> Maybe String
getSeq x y = if x `isSubsequenceOf` y
                then Just y
                else Nothing

{- main = print $ fmap (\a -> fmap (\b -> getSeq a b) blist) alist -}
{- [Just "awe",Just "bword",Just "fc"] -}
{- main = print $ foldl1 (<>) $ fmap (filter (/= Nothing)) $ fmap (\a -> fmap (\b -> getSeq a b) blist) alist -}

main = print $ filter (/= Nothing) $ liftA2 getSeq alist blist
