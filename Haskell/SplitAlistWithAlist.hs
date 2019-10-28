module SplitAlistWithAlist where

-- (cons 1 2) == 1: [2]
-- (car '(1)) == head [1]
-- (cdr '(1)) == tail [1]

splitWithList :: (Eq a) => [a] -> [a] -> [a] -> Int -> [[a]]
splitWithList = \alist blist before n ->
              if (null alist) then
                  (if (null blist) then (reverse $ removeN before n): [alist] else [])
                  else if (null blist) then
                       (reverse $ removeN before n): [alist]
                       else if ((head alist) /= (head blist)) then
                            splitWithList (tail alist) blist ((head alist): before) n
                            else
                            splitWithList (tail alist) (tail blist) ((head alist): before) n

removeN :: [a] -> Int -> [a]
removeN = \alist n ->
        if (n == 0) then
           alist
           else
           removeN (tail alist) (n - 1)

splitListWithList alist blist =
                  splitWithList alist blist [] $ lengthList blist

-- lengthN :: (Eq a) => [a] -> Int -> Int
-- lengthN = 
--        \x n -> if (null x) then
--            n
--            else lengthN (tail x) (n+1)
-- 
-- lengthList alist = lengthN alist 0

lengthList :: [a] -> Int
lengthList alist = f alist 0
           where
                f [] n = n
                f (x:xs) n = f xs (n+1)


-- main = 
--       putStrLn $ show $ splitListWithList [1,2,3,4,5] [3]
-- import SplitAlistWithAlist
-- splitListWithList [1,2,3] [2]  will be  [[1],[3]]
-- splitListWithList [1,2,3] [5]  will be  []
-- splitListWithList [1,2,3] [3]  will be  [[1,2],[]]
-- splitListWithList [1,2,3] [1]  will be  [[],[2,3]]
