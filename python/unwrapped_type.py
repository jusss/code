from functools import *
from operator import *

# Type Applications
# import Control.Monad
# :set -XTypeApplications
# :t fmap @((->)_)
# fmap @((->)_) :: (a -> b) -> (_ -> a) -> _ -> b
# :t fmap @[]
# fmap @[] :: (a -> b) -> [a] -> [b]

# there're two ways to define function, define with curry like 
# liftA2_func = lambda f: lambda xs: lambda ys: [ f(x,y) for x in xs for y in ys ]
# so call will be liftA2_func(operator.add)([1,2,3])([3,6])
# or use functools.partial to curry
# liftA2_func = lambda f, xs, ys: [ f(x,y) for x in xs for y in ys ]
# liftA2_func(operator.add, [1,2,3],[4,5])
# when need curry, partial(liftA2_func, operator.add)([1,2,3],[4,5])


# Reader, [], Cont
# liftA2 define [Reader, [], Cont] [fmap, ap, bind, join]


# Reader
fmap_func = lambda g, f: lambda x: g(f(x))
compose = fmap_func

fmap_list = lambda f, xs: [ f(x) for x in xs ]

# Cont r a :: (a -> r) -> r
# Cont r a = ContT r (Data.Functor.Identity) a
# fmap :: (a -> b) -> ContT r m a -> ContT r m b
# fmap_cont :: (a->b) -> ((a->r)->r ) -> (b->r)->r
# fmap_cont a b _ = b a
# fmap_cont a b = \_ -> b a
fmap_cont = lambda a, b: lambda _: b(a)

#(<*>) @((->)_) :: (_ -> a -> b) -> (_ -> a) -> _ -> b
# ap_func(zip, tail)([1,2,3])
# zip <*> tail $ xs == zip xs $ tail xs
# fmap (uncurry something) $ zip == zipWith something
ap_func =  lambda g, f: lambda x: g(x, f(x))
ap = ap_func

# return @((->)_) :: a -> _ -> a
return_func = lambda x: lambda f: f(x)
pure = return_func

# join m = m >>= id
# join (fmap f m) = m >>= f

#join @[] :: [[a]] -> [a]
join_list = lambda m: list(reduce(lambda x,y: x+y, m))

# join @((->)_) :: (_ -> _ -> a) -> _ -> a
# join :: ((a->b)->(a->b)->c) -> (a->b) -> c
# join :: (w -> (w->a)) -> w -> a
join_func = lambda f: lambda x: f(x,x)
# join_func (+) 3 == (+) 3 3 == 6
# join (*) <$> [1..6] == (join (*)) <$> [1..6] == (\x -> (*) x x) <$> [1..6] == fmap (\x -> (*) x x) [1..6] == [1,4,9,16,25,36]
# join (*) == \x -> (*) x x
# join (*) <$> xs == fmap (\x -> (*) x x) xs
# fmap_list(join_func(mul), [1,2,3])
# fmap_list(join_func(operator.mul), [1,2,3])

# newtype ContT r m a = ContT { runContT :: (a -> m r) -> m r }
# import Control.Monad.Trans.Cont, import Control.Monad
# join_cont = lambda f, k: f(k, k) is still join_func, the type is wrong, ref bind_cont

# join :: Monad m => m (m a) -> m a
# join :: ((((a->r)->r) -> r) -> r) -> ((a->r)->r)
# join :: ((((a->r)->r) -> r) -> r) -> (a->r)->r
# @djnn ((((a->r)->r) -> r) -> r) -> ((a->r)->r)
# join_cont a b = a (\c -> c b)
join_cont = lambda a, b: a(lambda c: c(b))

# (>>=) @((->)_) :: (_ -> a) -> (a -> _ -> b) -> _ -> b
# (>>=) :: (r->a) -> (a->r->b) -> r -> b
# >>= a b c = b (a c) c
bind_func = lambda g, f: lambda x: f(g(x),x)
# (>>=) @[] :: [a] -> (a -> [b]) -> [b]
bind_list = lambda xs, f: join_list(fmap_list(f, xs))

# Cont :: ((a -> r) -> r) -> Cont r a
# (>>=) :: Monad m => m a -> (a -> m b) -> m b
# (>>=) :: ((a->r)->r) -> (a->(b->r)->r) -> (b->r) -> r
# (>>=) a b c = a (\d -> b d c)
# Cont f >>= g = \ar -> f (\a -> g a ar)
bind_cont = lambda g: lambda f: lambda k: g(lambda x: f(x,k))

# Kleisli composition, Kleisli arrow, used for a -> Either b a
# (>=>) @((->)_) :: (a -> _ -> b) -> (b -> _ -> c) -> a -> _ -> c
fish_func = lambda g, f: lambda x, y: f(g(x,y), y)

# (>=>) @[] :: (a -> [b]) -> (b -> [c]) -> a -> [c]
# (>=>) = \f g -> join . fmap g . f
# f >=> g = join . fmap g . f
# (>=>) = \f g -> \a -> join (g <$> f a)
fish_list = lambda g, f: lambda a: join_list(fmap_list(f, g(a)))
# since join (fmap f m) = m >>= f
fish_list = lambda g, f: lambda a: bind_list(g(a), f)




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

# liftA2_list = lambda f: lambda xs: lambda ys: [ f(x,y) for x in xs for y in ys ]
liftA2_list = lambda f, xs, ys: [ f(x,y) for x in xs for y in ys ]

# fs <*> xs = [ f x | f <-fs, x<-xs ]
ap_list = lambda fs, xs: [ f(x) for f in fs for x in xs ]

