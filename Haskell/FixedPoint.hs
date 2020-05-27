import Control.Monad.Fix
import Prelude hiding (reverse)

--foldl f z [] = z
--foldl f z (x:xs) = foldl f (f z x) xs

gg _foldl f z [] = z
gg _foldl f z (x:xs) = _foldl f (f z x) xs

-- lambda
--foldl = \f result list ->
--    if (null list) then result
--    else foldl (f result (head list)) (tail list)

--gg = \foldl f result list ->
--    if (null list) then result
--    else foldl f (f result (head list)) (tail list)

foldl' f z [] = z
foldl' f z (x:xs) = gg foldl' f (f z x) xs

-- 1. based on foldl defintion
-- 2. get gg from foldl = fix gg, which means gg foldl = foldl
-- 3. re-write foldl with gg, get foldl'

-- main = print $ foldl' (+) 0 [1..3]

-----------------------------------------------------------------
--reverse l = rev l []
--    where
--    rev [] a = a
--    rev (x:xs) a = rev xs (x:a)        

--foldr k z = go
--          where
--            go []     = z
--            go (y:ys) = y `k` go ys




-- f2 n accum = if n == 1 then accum else f2 (n-1) (n * accum)
f2' f2 n accum = if n==1 then accum else f2 (n-1) (n* accum)
--f2N n accum = if n ==1 then accum else f2' f2N (n-1) (n* accum)
f2N n accum = if n ==1 then accum else fix f2' (n-1) (n* accum)
--main = print $ f2N 10 1


--f3 = \g -> f2 this use f2's define, so f3 f3' will call f2, not ok
--f3' n accum = if n == 1 then accum else f3 f3' (n-1) (n* accum)
--main = print $ f3' 10 1

--GHC.List.reverse
--reverse l = rev l []
--    where
--    rev [] a = a
--    rev (x:xs) a = rev xs (x:a)        

--reverse l = fix rev' l []
--        where
--            rev' rev [] a = a
--            rev' rev (x:xs) a = rev xs (x:a)


reverse [] = []
reverse (x:xs) = reverse xs ++ [x]

reverse' f [] = []
reverse' f (x:xs) = f xs ++ [x]
--main = print $ reverse' (reverse' reverse) [1,2,3]

--const x _ =  x
--f' = const f
--f = fix (const f)
--f' f = f
-- any function could be a fixed point of other functions, recursive or not
reverse'' = const reverse
main = print $ reverse'' reverse [1,2,3]

