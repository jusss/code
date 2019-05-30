class MyType(type):
    def __new__(cls,name,bases,attr):
        if not attr.get("fun",False):
            raise NotImplementedError
        print(attr)
        #print(dir(attr['__init__']))
        return super().__new__(cls,name,bases,attr)

class Foo(metaclass=MyType):
    fun = 1
    """
    def __init__(self):
        self.fun=1
    """

d=Foo()

class Meta2(type):
    def __call__(cls,*args,**kwargs):
        obj = type.__call__(cls, *args, **kwargs)
        obj.check_bar()
        return obj

class AbstractFoo(metaclass=Meta2):
    def check_bar(self):
        if self.bar is None:
            raise NotImplementedError

class Good(AbstractFoo):
    def __init__(self):
        self.bar=1

class Bad(AbstractFoo):
    bar=1

dd=Good()
#d2=Bad()
            
#https://stackoverflow.com/questions/23831510/abstract-attribute-not-property

#maybe just,  and foo need be a class-variable, not instance's attribute
@property
@abstractmethod
def foo(self):
    raise NotImplementedError
