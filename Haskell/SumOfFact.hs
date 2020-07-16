
-- f n = 1! + 2! + 3! + 4! + 5! + .. + n!
fact 1 = 1
fact n = n * (fact (n-1))
f n = sum $ fmap fact [1..n]  -- O(n)

main = print $ f 3
