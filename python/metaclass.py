class Meta1(type):
    def __new__(cls,name,base,attr):
        print(attr)
        if not attr.get('add',False):
            raise NotImplementedError
        else:
            _add = attr['add']
            attr['add1'] = lambda self,v: v+1
            #f >>= g = \x -> g (f x) x
        return type.__new__(cls,name,base,attr)

class T1:
    __metaclass__ = Meta1
    def __init__(self):
        pass
    def add(self, x):
        return x+2

d=T1()
print(d.add(3))
print(d.add1(2))




            
