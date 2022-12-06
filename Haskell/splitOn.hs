import Data.List

slice alist (start, end) = drop start $ take end alist

getIndexList subList sourceList = fmap fst $ filter (isPrefixOf subList . snd) $ zip [0..] $ tails sourceList

splitOn subList sourceList = case getIndexList subList sourceList of
    [] -> [sourceList]
    indexList -> fmap (slice sourceList) $  [(0, head indexList)] <> (zip starts (tail indexList)) <> [(last starts, length sourceList)] where
        starts = fmap (+ (length subList)) indexList

main = print $ splitOn "/a/b" "this is a test /ab/c/a/b /c /a/b absurd"
{- main = print $ splitOn "/a/b" "this " -}
{- main = print $ splitOn "/a/b" "/a/b" -}

{- _splitOn x y = let (xs, ys) = span (not . isPrefixOf x) (init (tails y)) in (map head xs, map head ys) -}

{- getIndexList subList sourceList = filter (/= -1) $ fmap (\x -> if (subList `isPrefixOf` (snd x)) then (fst x) else -1) $ zip [0..(length sourceList)] $ tails sourceList -}

{- getIndexList subList sourceList = fmap fst $ filter ((subList `isPrefixOf`) . snd) $ zip [0..(length sourceList)] $ tails sourceList -}
