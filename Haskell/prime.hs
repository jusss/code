p = s [2..]
s (x:xs) = x : s [ i | i <- xs , mod i x /=0]
main = print $ take 100 p
