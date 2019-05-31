from typing import Callable, TypeVar
from abc import ABCMeta, abstractmethod
a=TypeVar('a')
b=TypeVar('b')

class Functor(metaclass=ABCMeta):
    @abstractmethod
    def fmap(self, func):
        pass

class Maybe(Functor, metaclass=ABCMeta):
    @abstractmethod
    def fmap(self, f: Callable[[a],b]) -> "Maybe":
        pass

class Just(Maybe):
    def __init__(self,value):
        self._value=value
    def fmap(self, f: Callable[[a],b]) -> "Just":
        return Just(f(self._value))
    def __str__(self):
        return f"Just {self._value}"
    def __repr__(self):
        return self.__str__()

class Nothing(Maybe):
    def fmap(self, f: Callable[[a],b]) -> "Nothing":
        return Nothing()
    def __str__(self):
        return "Nothing"
    def __repr__(self):
        return "Nothing"

def fmap(func, f):
    return f.fmap(func)

print(fmap(lambda x: x+1, Nothing()))
print(fmap(lambda x: x+1, Just(123)))

"""
this is something sort of typeclass in python



@nasyx
as a Maybe, you need class Maybe(Monad, Monoid, Applicative, Functor): pass
so you need to implement Monad, Applicative, Monoid, Functor's metaclass first,

"""
