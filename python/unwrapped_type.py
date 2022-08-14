from functools import partial, reduce
from toolz.functoolz import curry
from operator import add
# from math import atan as t, degree as z

# S is ap, K is return, I is id, is that something?

# Type Applications
# import Control.Monad
# :set -XTypeApplications
# :t fmap @((->)_)
# fmap @((->)_) :: (a -> b) -> (_ -> a) -> _ -> b
# :t fmap @[]
# fmap @[] :: (a -> b) -> [a] -> [b]

# there're two ways to define function, define with curry like 
# liftA2_list = lambda f: lambda xs: lambda ys: [ f(x,y) for x in xs for y in ys ]
# so call will be liftA2_list(operator.add)([1,2,3])([3,6])
# or use functools.partial to curry
# liftA2_list = lambda f, xs, ys: [ f(x,y) for x in xs for y in ys ]
# liftA2_list(operator.add, [1,2,3],[4,5])
# when need curry, partial(liftA2_list, operator.add)([1,2,3],[4,5])

# @curry # not work on lambda
# def zipWith(f, alist, blist):
    # return [ f(alist[i], blist[i]) for i in range(len( alist if len(alist) < len(blist) else blist)) ]

# f = a_decorator(lambda ...)
# f = curry(lambda x, y: x+y)

# c=zipWith(add, [1,2,3])
# print(c([4,5]))

# Reader, [], Cont
# liftA2 define [Reader, [], Cont] [fmap, ap, liftA2, bind, join, return, fish]
# liftA2 define [func, list, cont] [fmap, ap, liftA2, bind, join, return, fish]

###########################################################

# Reader r a :: r -> a
fmap_func = curry(lambda g, f: lambda x: g(f(x)))
compose = fmap_func

# (<*>) @((->)_) :: (_ -> a -> b) -> (_ -> a) -> _ -> b
# ap_func(zip, tail)([1,2,3])
# zip <*> tail $ xs == zip xs $ tail xs
# fmap (uncurry something) $ zip == zipWith something
# S g f x = g x (f x)
ap_func =  curry(lambda g, f, x: g(x, f(x)))
ap = ap_func

# liftA2 :: (a -> b -> c) -> f a -> f b -> f c
# liftA2 :: (a -> (b->c)) -> (e->a) -> (e->b) -> e->c
# liftA2 f g h = \e -> f (g e) (h e)
# S (K f) g h = S(S (K f) g) h = S (B f g) h
# S is ap, K is const, I is id, B is fmap, W is join, C is flip
# liftA2 f x = (<*>) (fmap f x)

# @curry
# def liftA2_func(f, g, h):
    # return lambda e: f(g(e),h(e))

liftA2_func = curry(lambda f, g, h: lambda e: f(g(e),h(e)))

# (>>=) @((->)_) :: (_ -> a) -> (a -> _ -> b) -> _ -> b
# >>= a b c = b (a c) c
bind_func = curry(lambda g, f, x: f(g(x),x))

# join @((->)_) :: (_ -> _ -> a) -> _ -> a
# join :: ((a->b)->(a->b)->c) -> (a->b) -> c
# join :: (w -> (w->a)) -> w -> a
# W f x = f x x
join_func = curry(lambda f, x: f(x,x))
# join_func (+) 3 == (+) 3 3 == 6
# join (*) <$> [1..6] == (join (*)) <$> [1..6] == (\x -> (*) x x) <$> [1..6] == fmap (\x -> (*) x x) [1..6] == [1,4,9,16,25,36]
# join (*) == \x -> (*) x x
# join (*) <$> xs == fmap (\x -> (*) x x) xs
# fmap_list(join_func(mul), [1,2,3])
# fmap_list(join_func(operator.mul), [1,2,3])

# return @((->)_) :: a -> _ -> a
return_func = lambda x: lambda _: x
# return_func = const
pure = return_func

# Kleisli composition, Kleisli arrow, used for a -> Either b a
# (>=>) @((->)_) :: (a -> _ -> b) -> (b -> _ -> c) -> a -> _ -> c
fish_func = lambda g, f: lambda x, y: f(g(x,y), y)
###########################################################

# []
fmap_list = lambda f, xs: [ f(x) for x in xs ]

# fs <*> xs = [ f x | f <-fs, x<-xs ]
ap_list = lambda fs, xs: [ f(x) for f in fs for x in xs ]

# liftA2_list is fmap inside fmap, like for in for
# liftA2 f alist blist = join (fmap (\a -> fmap (\b -> f a b) blist) alist)
# liftA2 f xs ys = [f x y | x <- xs, y <- ys]
# liftA2_list = lambda f: lambda xs: lambda ys: [ f(x,y) for x in xs for y in ys ]
liftA2_list = lambda f, xs, ys: [ f(x,y) for x in xs for y in ys ]


# (>>=) @[] :: [a] -> (a -> [b]) -> [b]
bind_list = lambda xs, f: join_list(fmap_list(f, xs))

# join m = m >>= id
# join (fmap f m) = m >>= f

#join @[] :: [[a]] -> [a]
join_list = lambda m: list(reduce(lambda x,y: x+y, m))

return_list = lambda x: [x]

# (>=>) @[] :: (a -> [b]) -> (b -> [c]) -> a -> [c]
# (>=>) = \f g -> join . fmap g . f
# f >=> g = join . fmap g . f
# (>=>) = \f g -> \a -> join (g <$> f a)
fish_list = lambda g, f: lambda a: join_list(fmap_list(f, g(a)))
# since join (fmap f m) = m >>= f
fish_list = lambda g, f: lambda a: bind_list(g(a), f)


#######################################################

# Cont r a :: (a -> r) -> r
# Cont r a = ContT r (Data.Functor.Identity) a
# fmap :: (a -> b) -> ContT r m a -> ContT r m b
# fmap_cont :: (a->b) -> ((a->r)->r ) -> (b->r)->r
# fmap_cont a b _ = b a
# fmap_cont a b = \_ -> b a
fmap_cont = lambda a, b: lambda _: b(a)

# <*> :: f (a->b) -> f a -> f b
# <*> :: Cont r (a->b) -> Cont r a -> Cont r b
# <*> :: (((a->b) -> r) -> r) -> ((a->r)->r) -> (b->r) -> r
# @djinn (((a->b) -> r) -> r) -> ((a->r)->r) -> (b->r) -> r
# lambdabot :f a b c = b (\ d -> a (\ e -> c (e d)))

# @djinn (((a->b) -> r) -> r) -> ((a->r)->r) -> (b->r) -> r; lambdabot :f a b c = b (\ d -> a (\ e -> c (e d))); tomsmeding :that djinn output is incorrect as an implementation for Cont though, because it evaluates the argument before the function :p
# monochrom :f a b c = a (\e -> b (\d -> c (e d)))

ap_cont = lambda a, b, c: a(lambda e: b(lambda d: c(e(d))))


# liftA2 :: (((a->b->c) -> r) -> r) -> ((a->r)->r) -> ((b->r) -> r) -> (c->r)->r
# f a b c d = c (\ e -> b (\ f -> a (\ g -> d (g f e))))

# liftA2_cont f ma mb = ma >>= \a -> mb >>= \b -> pure $ f a b
liftA2_cont = lambda f, ma, mb: bind_cont(ma, (lambda a: bind_cont(mb, lambda b: return_cont(f(a,b)))))

# Cont :: ((a -> r) -> r) -> Cont r a
# (>>=) :: Monad m => m a -> (a -> m b) -> m b
# (>>=) :: ((a->r)->r) -> (a->(b->r)->r) -> (b->r) -> r
# (>>=) a b c = a (\d -> b d c)
# Cont f >>= g = \ar -> f (\a -> g a ar)
bind_cont = lambda g: lambda f: lambda k: g(lambda x: f(x,k))

# newtype ContT r m a = ContT { runContT :: (a -> m r) -> m r }
# import Control.Monad.Trans.Cont, import Control.Monad
# join_cont = lambda f, k: f(k, k) is still join_func, the type is wrong, ref bind_cont

# join :: Monad m => m (m a) -> m a
# join :: ((((a->r)->r) -> r) -> r) -> ((a->r)->r)
# join :: ((((a->r)->r) -> r) -> r) -> (a->r)->r
# @djnn ((((a->r)->r) -> r) -> r) -> ((a->r)->r)
# join_cont a b = a (\c -> c b)
join_cont = lambda a, b: a(lambda c: c(b))


return_cont = lambda a: lambda k: k(a)

# >=> :: (a -> m b) -> (b -> m c) -> a -> m c
# >=> :: (a -> (b->r)->r) -> (b -> (c->r)->r) -> a -> (c->r) -> r
# fish_cont a b c d = a c (\ e -> b e d)
fish_cont = lambda a, b, c, d: a(c, (lambda e: b(e,d)))



########### Data.List #######
# allEqual :: (Eq a) => [a] -> Bool
# allEqual = and $ zipWith (==) <*> tail

head = lambda xs: xs[0]
last = lambda xs: xs[-1]
init = lambda xs: xs[:-1]
tail = lambda xs: xs[1:]
eq = lambda x, y: x == y
not_eq = lambda x, y: x != y

reverse = lambda xs: list(reversed(xs))

zipWith = lambda f, alist, blist: [ f(alist[i], blist[i]) for i in range(len( alist if len(alist) < len(blist) else blist)) ]

all_equal = lambda xs: all(ap_func(partial(zipWith, eq), tail)(xs))

identity = lambda x: x
const = lambda x, y: x

remove_dup = lambda alist: [alist[i] for i in range(len(alist)) if alist[i] not in alist[i+1::]]

intersect = lambda xxs: list(reduce(lambda xs, ys: [x for x in xs if x in ys], xxs))

# print(intersect([[1,2,3],[3,4,23],[7,8,2,3,56]]))

findElementInList = lambda elem, alist: [p for e, p in zip(alist, range(len(alist))) if elem == e]

# print(findElementInList('a', "abcdaewa"))






# fmap :: (a->b) -> (e->a) -> (e->b)
# fmap :: (a->(b->c)) -> (e->a) -> e -> b->c
# fmap (+) (+1) 

"""

"@djinn (((a->b) -> r) -> r) -> ((a->r)->r) -> (b->r) -> r; lambdabot :f a b c = b (\ d -> a (\ e -> c (e d))); tomsmeding :that djinn output is incorrect as an implementation for Cont though, because it evaluates the argument before the function :p
" then what's the right implementation?
monochrom :f a b c = a (\e -> b (\d -> c (e d)))
how u work this out? type tetris?
Cale :Just thinking about what it means, probably. Though I'm not sure I would consider either option "wrong".
monochrom :I learned continuations.
monochrom :Or at least continuation passing style.
Cale :In monochrom's version, we first run a, getting some function e :: a -> b, and then we run b, getting some value d :: a, and then we finish (apply the final continuation c) with the result e d of applying the function we got to the value we got.
Cale, and djinn's version is wrong?
Cale :No, it just gets the argument first, then the function, and calls the final continuation with the same result.
Cale :The evaluation order will be different, but in any case where both terminate, the result will be the same.
Cale :If this were ContT and there were effects, then executing things in a different order might make effects occur in a different order, but it's difficult to say that one way is "wrong".
Cale :I do like the version which does the function first though, it's a little more obvious to go left to right.
should this liftA2 on Cont ever be used? or never be used?
Cale :There are probably cases. Cases where you should use Cont/ContT are already fairly rare as it is.
monochrom :But ContT would be way more complex than "a (\e -> ...)" :)
Cale :(true)
Cale :But if you're going to use it, one of the main reasons is to be able to get hold of combinators like liftA2 and sequence
Cale :Especially the recursive things like sequence can be kind of annoying to write by hand when manipulating things in continuation passing style

"""
