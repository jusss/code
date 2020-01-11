import Data.List

-- f [1,2,3] 0 == 123
f :: [Int] -> Int -> Int
f [] _ = 0
f x n = (last x) * (10 ^ n) + f (init x) (n + 1)

-- f2 [1,1,1,1] 0 == 15
f2 :: [Int] -> Int -> Int
f2 [] _ = 0
f2 x n = (last x) * (2 ^ n) + f2 (init x) (n + 1)

-- f3 123 = [3,2,1]
f3 x = if (div x 10) == 0 then [x]
    else
        x - (div x 10) * 10 : [] <> f3 (div x 10)

-- f4 123 = [1,2,3]
f4 x = reverse $ f3 x


-- <Axman6> > let  digits 0 acc = acc; digits n acc = case quotRem n 10 of (y,r)
--         -> digits y (r:acc) in digits 1234567 []
-- <lambdabot>  [1,2,3,4,5,6,7]

-- f5 15 = 1111
-- f6 1111 = 15

-- f5 [1,2,3] = [100,20,3]
f5 x = if (Data.List.null x) then [] else [(head x) * (10 ^ ((length x) - 1))] <> f5 (tail x)


main = print $ f4 123


