import Data.List
import Data.Maybe

-- 3215 1325 
a1 = [3,2,1,5]
a2 = [1,3,2,5]

-- 3465 3456


-- work on without 0

f l1 l2 = 
    if (length l1) == (length l2) then
        -- no 0
        if (head l1) /= (head l2) then
        (fromJust (elemIndex (head l2) l1), fromJust (elemIndex (head l2) l2))
        else f (tail l1) (tail l2)
    else
        if (length l1) - (length l2) == 1 then
        -- one 0
        (fromJust (elemIndex 0 l1), 0)
        else
        -- more 0 than 1
        (0, fromJust ((head l1) `elemIndex` l2) + (length l1) - (length l2))
            
-- 3907 397
-- 1900 190
-- 1000 1
-- 3005 35
-- 30019 139
-- 300052 352

main = print $ f [3,0,0,1,9] [1,3,9]
