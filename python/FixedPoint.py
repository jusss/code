from functools import partial

reverse = lambda l: [] if l == [] else reverse(l[1:]) + [l[0]]
#print(reverse([1,2,3]))

reverse_ = lambda f,l: [] if l == [] else f(l[1:]) + [l[0]]
#print(reverse_(reverse,[1,2,3]))

rev1 = partial(reverse_, reverse)
rev2 = partial(reverse_, rev1)
print(reverse_(rev2,[1,2,3]))

const = lambda x, _: x
_reverse = partial(const, reverse)
print(_reverse(_reverse(reverse))([1,2,3]))



"""
const x _ =  x
f' = const f
f = fix (const f)
f' f = f

-- any function could be a fixed point of other functions, recursive or not
reverse [] = []
reverse (x:xs) = reverse xs ++ [x]

reverse' f [] = []
reverse' f (x:xs) = f xs ++ [x]

main = print $ reverse' (reverse' reverse) [1,2,3]


f2 = lambda f, n, accum: accum if n==1 else f ((n-1), (n* accum))
f2NoRecur = lambda n, accum: accum if n ==1 else f2 (f2NoRecur, (n-1), (n* accum))
print(f2NoRecur(990,1))

"""


