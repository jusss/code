s (x:xs) = x: s[i|i <- xs, mod i x /= 0]
s[] = []
main = print $ s [2..9]
