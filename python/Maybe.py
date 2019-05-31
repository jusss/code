from abc import ABCMeta, abstractmethod
from Monad import *

class Maybe(Monad, Applicative, Functor, metaclass=ABCMeta):
    pass

class _Nothing(Monoid, Maybe):

    def __init__(self):
        # mempty :: m a
        # improperly, 'cause mempty is a value not a function
        # self.mempty = self
        pass

    @property
    def mempty(self):
        return self

    # mappend :: m a -> m a -> m a
    # mempty = Nothing
    # mappend Nothing y = y
    # mappend x Nothing = x
    # mappend (Just x) (Just y) = Just (x <> y)

    def mappend(self, ma):
        if not isinstance(ma, Maybe):
            raise ValueError("not Maybe type")
        return ma

    # unit :: a -> m a
    def unit(self, a):
        return self

    # <$> :: (a->b) -> f a -> f b
    # f a <$> (a->b) = f b
    def fmap(self, f):
        return self

    # <*> :: f (a->b) -> f a -> f b
    # f a <*> f (a->b) = f b
    def apply(self, fa):
        if not isinstance(fa, Maybe):
            raise ValueError("not Maybe type")
        if not callable(fa.join()):
            raise ValueError("object is not callable")
        return self

    # >>= :: m a -> (a -> m b) -> m b
    # m a >>= (a -> m b) = m b
    def bind(self,  f):
        return self

    # join :: m (m a) -> m a
    def join(self):
        return self

    # isNothing :: m a -> m a
    def isNothing(self, ma):
        if not isinstance(ma, Maybe):
            raise ValueError("not Maybe type")
        return self

Nothing = _Nothing()

class Just(Monoid, Maybe):
 
    def __init__(self, value):
        self.value = value

    @property
    def mempty(self):
        return Nothing

    # mappend :: m a -> m a -> m a
    # mempty = Nothing
    # mappend Nothing y = y
    # mappend x Nothing = x
    # mappend (Just x) (Just y) = Just (x <> y)

    def mappend(self, ma):
        if not isinstance(ma, Maybe):
            raise ValueError("not Maybe type")
        if ma == Nothing:
            return ma
        if isinstance(self.value, str) and isinstance(ma.join(), str):
            return self.unit(self.value + ma.join())
        if isinstance(self.value, list) and isinstance(ma.join(), list):
            return self.unit(self.value + ma.join())
        raise NotImplementedError
    
    # unit :: a -> m a
    def unit(self, a):
        return Just(a)

    # <$> :: (a->b) -> f a -> f b
    # f a <$> (a->b) = f b
    def fmap(self, f):
        return self.unit( f (self.value) )

    # <*> :: f (a->b) -> f a -> f b
    # f a <*> f (a->b) = f b
    def apply(self, fa):
        if not isinstance(fa, Maybe):
            raise ValueError("not Maybe type")
        if not callable(fa.join()):
            raise ValueError("object is not callable")
        return self.unit( fa.join() (self.value) )

    # >>= :: m a -> (a -> m b) -> m b
    # m a >>= (a -> m b) = m b
    def bind(self,  f):
        return f(self.value)
 
    # join :: m (m a) -> m a
    def join(self):
        return self.value

    # isNothing :: m a -> m a
    def isNothing(self, ma):
        if not isinstance(ma, Maybe):
            raise ValueError("not Maybe type")
        if ma == Nothing:
            return Nothing
        else:
            return self.unit([self.join(), ma.join()])

#############################################        
if __name__ == '__main__' :
    unit = lambda v, T: T(v)

    Just3 = Just (3)
    Just5 = Just (5)

    print(Just3.fmap(lambda x: x+2)
                  .join()
    )

    print(
        Just3.apply( Just (lambda x: x+2) )
                 .join()
    )

    print(
        Just3.bind( lambda x: unit(x+2,Just))
    .join()
    )

    print(
        Nothing.isNothing(Nothing).isNothing( unit(3,Just) )
        .join()
    )

    print(
        Just3.isNothing(Just5).isNothing(Just5)
    .join()
    )

    print(
        Just("a").mappend(Just("b"))
    .join()
    )

    print(
        Just("a").mempty
        )

    #left identity: return a >>= f == f a
    print(
        unit(3, Just).bind(lambda x: unit(x+2, Just)).join()
        ==
        (lambda x: unit(x+2, Just))(3).join()
        )

    #right identity: m >>= return == m
    print(
        Just(3).bind(lambda x: unit(x,Just)).join()
        ==
        Just(3).join()
        )

    #associativity: m >>= f >>= g   ==   m >>= (\x -> f x) >>= g
    m = Just(3)
    f = lambda x: unit(x+2,Just)
    g = lambda x: unit(x+1,Just)
    print(
        m.bind(f).bind(g).join()
        ==
        m.bind(lambda x: f(x)).bind(g).join()
        )
