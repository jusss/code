import Data.List hiding (groupBy)
import Control.Applicative

concatOverlap :: [Int] -> [Int] -> [[Int]]
concatOverlap x y = if (any (==True) $ liftA2 (==) x y) 
                    then [nub $ sort $ x ++ y]
                    else [x, y]

--1. [1,5] to [1..5], then concat them , then nub them, and sort
--2. group by a-b /= 1, get the length of groups

tuple2List (x,y) = [x..y]

r2 = fmap concat $ groupBy (\x y -> (last x) - (head y) == -1) $ groupBy (\a b -> (b-a) == 1) $ sort $ nub $ concat $ fmap tuple2List [(1,5),(6,10)]

main = print $ applyOnTwoElem intersect $ fmap (\(x,y) -> [x..y]) [(-61,106),(-120,473)]

groupBy :: (a -> a -> Bool) -> [a] -> [[a]]
groupBy _ [] = []
groupBy p' (x':xs') = (x' : ys') : zs'
  where
    (ys',zs') = go p' x' xs'
    go p z (x:xs)
      | p z x = (x : ys, zs)
      | otherwise = ([], (x : ys) : zs)
      where (ys,zs) = go p x xs
    go _ _ [] = ([], [])

sumOfIntervals :: [(Int, Int)] -> Int
sumOfIntervals _intervals = 
    let intervals = nub _intervals  -- remove duplicate elements
        s = sort . nub $ (concat $ fmap (\(x,y) -> [x..y]) intervals)
    in
        if (length intervals) == 1 then snd (head intervals) - (fst (head intervals))  -- [(1,5)]
        else
        -- [(1,5),(6,10)]
        if [minimum s..maximum s] == s
        then if (all (==[]) $ applyOnTwoElem intersect $ fmap (\(x,y) -> [x..y]) intervals)
              then       
                sum $ fmap (\(x,y) -> y - x) intervals
              else maximum s - minimum s
        else 
            let r2 = fmap concat $ groupBy (\x y -> (last x) - (head y) == -1) $ groupBy (\a b -> (b-a) == 1) s
            in  sum . fmap (\l -> last l - head l) $ r2 

deleteAllElements x xs = filter (`notElem` [x]) xs
--deleteAllElements 2 [1,2,2,3] == [1,3]

--getAllIndexOfElem :: Eq a => [a] -> [a] -> [(a, [Int])]
--getAllIndexOfElem [x] y = [(x, (elemIndices x y))]
--getAllIndexOfElem x y = 
--    let i = (elemIndices (head x) y) 
--    in 
--        if i == [] then [(head x, [])] <> (getAllIndexOfElem (tail x) y) 
--        else [(head x, i)] <> (getAllIndexOfElem (tail x) (deleteAllElements (head x) y))

-- getAllIndexOfElem [1,1,2,3,9,2,5,1,7,9] [1,1,2,3,9,2,5,1,7,9] ==
-- [(1,[0,1,7]),(1,[]),(2,[0,3]),(3,[0]),(9,[0,3]),(2,[]),(5,[0]),(1,[]),(7,[0]),(9,[])]
--getElemIndexes l = filter (\(x,y) -> y /= []) $ getAllIndexOfElem l l 

-- [1,1,2,3,9,2] -> [(1,[0,1]),(1,[0,1]),(2,[2,5]),(3,[3]),(9,[4]),(2,[2,5])]
getAllIndexOfElem :: Eq a => [a] -> [a] -> [(a, [Int])]
getAllIndexOfElem [x] y = [(x, (elemIndices x y))]
getAllIndexOfElem (x:xs) y = [(x, elemIndices x y)] <> (getAllIndexOfElem xs y)

-- [1,1,2,3,9,2] -> [(1,[0,1]),(2,[2,5]),(3,[3]),(9,[4])]
getElemIndexes l = nub $ getAllIndexOfElem l l

-- [1,1,2,3,9,2] -> [(1,2),(2,2),(3,1),(9,1)]
getElemTimes l = fmap (fmap length) $ getElemIndexes l

-- [1,1,2,3,9,2] -> [[1,1],[2,2],[3],[9]]
gatherSameElem l = fmap (\(x,y) -> replicate y x) . sortOn fst . getElemTimes $ l


f3 :: (a -> a -> c) -> [a] -> [a] -> [c]

f3 f [l,r] y = [f l r]
f3 f x y = (fmap (\z -> f (head x) z) (tail y)) <> (f3 f (tail x) (tail y))

applyOnTwoElem f l = f3 f l l

-- f3 f x y = if (length x == 2) then [f (head x) (last x)]
--            else (fmap (\z -> f (head x) z) (tail y)) <> (f3 f (tail x) (tail y))

-- main = (print $ f3 (,) [0,1,2,3] [0,1,2,3])  >>   (print $ f3 (+) [0,1,2,3] [0,1,2,3])


-- [0,1,2,3] to [(0,1),(0,2),(0,3),(1,2),(1,3),(2,3)]
f :: [Int] -> [Int] -> [(Int, Int)]
f x y = 
    if (length x == 2) then [(head x, last x)]
    else (fmap (\z -> (head x,z)) (tail y)) <> (f (tail x) (tail y))

--main = print $ f [0,1,2,3] [0,1,2,3]

-- [0,1,3,7,9] to [0+1, 0+3, 0+7, 0+9, 1+3, 1+7, 1+9, 3+7...]
f2 :: [Int] -> [Int] -> [Int]
f2 x y = 
    if (length x == 2) then [head x + last x]
    else (fmap (\z -> (head x + z)) (tail y)) <> (f2 (tail x) (tail y))

-- main = print $ f2 [0,1,3,7,9] [0,1,3,7,9]
