module Data.String.Split
    ( slice
    , getIndexList
    , splitOn
    ) where

import Data.List

slice :: String -> (Int, Int) -> String
slice alist (start, end) = drop start $ take end alist

getIndexList :: String -> String -> [Int]
getIndexList subList sourceList = fmap fst $ filter (isPrefixOf subList . snd) $ zip [0..] $ tails sourceList

splitOn :: String -> String -> [String]
splitOn subList sourceList = case getIndexList subList sourceList of
    [] -> [sourceList]
    indexList -> fmap (slice sourceList) $  [(0, head indexList)] <> (zip starts (tail indexList)) <> [(last starts, length sourceList)] where
        starts = fmap (+ (length subList)) indexList

{- main = print $ splitOn "/a/b" "this is a test /ab/c/a/b /c /a/b absurd" -}
{- ~/web/upload-files/Data/String/Split.hs -}
