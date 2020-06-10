from functools import partial

reverse = lambda l: [] if l == [] else reverse(l[1:]) + [l[0]]
#print(reverse([1,2,3]))

reverse_ = lambda f,l: [] if l == [] else f(l[1:]) + [l[0]]
#print(reverse_(reverse,[1,2,3]))

reverse__ = lambda f: lambda l: [] if l == [] else f(l[1:]) + [l[0]]

#fix f = f (fix f)   
#fix = lambda f: f(fix(f)) //won't work in call-by-value eval strategy
#fix f = f (fix f) = \y -> f (fix f) y = f (\y -> fix f y) // outsider and inner eta-conversion

#fix f x = f (\y -> fix f y) x   //do twice eta-conversion
fix = lambda f,x: f((lambda y: fix(f,y)),x)  #will work in call-by-value

#fix f x = f (fix f) x  //do once eta-conversion is enough
fix2 = lambda f: lambda x: f(fix2(f))(x)

rev1 = partial(reverse_, reverse)
rev2 = partial(reverse_, rev1)
print(reverse_(rev2,[1,2,3]))

const = lambda x, _: x
_reverse = partial(const, reverse)
print(_reverse(_reverse(reverse))([1,2,3]))
print(fix(reverse_,[3,8,9]))
print(fix2(reverse__)([3,9,2]))


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

>>> fix = lambda f: lambda x: f(fix(f))(x)
>>> fac = lambda f: lambda n: (1 if n<2 else n*f(n-1))
>>> [fix(fac)(i) for i in range(10)]
[1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880]
>>> fib = lambda f: lambda n: 0 if n == 0 else (1 if n == 1 else f(n-1) + f(n-2))
>>> [ fix(fib)(i) for i in range(10) ]
[0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
https://rosettacode.org/wiki/Y_combinator#Haskell


<jusss> dminuoso: I tried to implement that Fix f type in kotlin, and Fix
        Maybe can't be implement
<jusss> dminuoso: make Maybe as a class with a parameter, Just and Nothing is
        another class inherit it
<jusss> dminuoso: but Fix <Maybe> couldn't exist, because Maybe need a A
<jusss> Fix<Maybe<A>> is ok
<jusss> but in haskell, we have Fix Maybe, not Fix (Maybe a)
<jusss> sealed class Maybe<A>; data class Just<A>(val x:A): Maybe<A>();  data
        class Nothing: Maybe<Any>()                                     [16:10]
<jusss> sealed class Fix<F>; data class MkFix<F:Fix<F>>(val x:F): Fix<F>(); 
<jusss> there couldn't be an object has Fix<Maybe>
<dminuoso> jusss: Most type systems are fairly limited in expressiveness.
<jusss> but we could have Fix Maybe in haskell, that's where I don't know
<jusss> dminuoso: so I wonder how they implement Fix type in their type system
<jusss> dminuoso: Kotlin, Java, other static type languages             [16:15]
<dminuoso> jusss: I reckon they cant.
<jusss> dminuoso: fix combinator is a common stuff on value level, even python
        can have that
<jusss> fix and const
<jusss> we could have fix combinator on value level in python, but in type
        level, I don't know                                             [16:24]

"""


