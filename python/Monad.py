from abc import ABCMeta, abstractmethod

class Functor(metaclass=ABCMeta):
    @abstractmethod
    def fmap(self, f):
        raise NotImplementedError

class Applicative(Functor, metaclass=ABCMeta):
    @abstractmethod
    def apply(self,  fa):
        raise NotImplementedError

    @classmethod
    def pure(cls,x):
        return cls(x)

class Semigroup(metaclass=ABCMeta):
    @abstractmethod
    def mappend(cls, ma):
        raise NotImplementedError
    
class Monoid(Semigroup, metaclass=ABCMeta):
    mappend = Semigroup.mappend
    @property
    @abstractmethod
    def mempty(self):
        raise NotImplementedError

class Monad( Applicative, Functor, metaclass=ABCMeta):
    @abstractmethod
    def bind(self, f):
        raise NotImplementedError
