from functools import partial, reduce
from toolz.functoolz import curry
from operator import add

# S is ap, K is return, I is id

# fmap @((->)_) :: (a -> b) -> (_ -> a) -> _ -> b
# fmap @[] :: (a -> b) -> [a] -> [b]

# @curry # not work on lambda
# def zipWith(f, alist, blist):
    # return [ f(alist[i], blist[i]) for i in range(len( alist if len(alist) < len(blist) else blist)) ]

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
fmap = fmap_list

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
# fmap :: (a -> b) -> ContT r m a -> ContT r m b
# fmap_cont :: (a->b) -> ((a->r)->r ) -> (b->r)->r
# fmap_cont a b _ = b a
# fmap_cont a b = \_ -> b a
fmap_cont = lambda a, b: lambda _: b(a)

# <*> :: f (a->b) -> f a -> f b
# <*> :: Cont r (a->b) -> Cont r a -> Cont r b
# <*> :: (((a->b) -> r) -> r) -> ((a->r)->r) -> (b->r) -> r
# lambdabot :f a b c = b (\ d -> a (\ e -> c (e d)))
# m :f a b c = a (\e -> b (\d -> c (e d)))

liftA2_cont = lambda a, b, c: a(lambda e: b(lambda d: c(e(d))))

# Cont :: ((a -> r) -> r) -> Cont r a
# (>>=) :: Monad m => m a -> (a -> m b) -> m b
# (>>=) :: ((a->r)->r) -> (a->(b->r)->r) -> (b->r) -> r
# (>>=) a b c = a (\d -> b d c)
# Cont f >>= g = \ar -> f (\a -> g a ar)
bind_cont = lambda g: lambda f: lambda k: g(lambda x: f(x,k))

# newtype ContT r m a = ContT { runContT :: (a -> m r) -> m r }

# join :: Monad m => m (m a) -> m a
# join :: ((((a->r)->r) -> r) -> r) -> ((a->r)->r)
# join :: ((((a->r)->r) -> r) -> r) -> (a->r)->r
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

dict_to_tuple_list = lambda _dict: [(k, v) for k, v in _dict.items()]
tuple_list_to_dict = lambda _tupel_list: dict(_tupel_list)

# intersect([[1,2,3],[3,4,23],[7,8,2]])
intersect = lambda xxs: list(reduce(lambda xs, ys: [x for x in xs if x in ys], xxs))

duplicate = lambda n, x: [x for i in range(n)]

generate_range = lambda xs: list(range(xs[0],xs[1]+1))

string2list = lambda x: [i for i in x]

list2string = lambda x: "".join(x)

findElementInList = lambda element, alist: [y for x, y in zip(alist, list(range(len(alist))) if x == element]

# fmap :: (a->b) -> (e->a) -> (e->b)
# fmap :: (a->(b->c)) -> (e->a) -> e -> b->c
# fmap (+) (+1)
