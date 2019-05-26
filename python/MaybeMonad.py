class Maybe:
    def __init__(self,value):
        self.value = value
        
    def of(self,value):
        return Maybe(value)

    def isNone(self):
        return True if self.value == None else False

    def map(self,f):
        if self.isNone():
            return self.of(None)
        return self.of(f(self.value))
    def join(self):
        return self.value

if __name__ == '__main__':
    """
            if a!=None:
                if b!=None:
                    if c!=None:
                        doSometing
    """

    a=None
    b=None
    c=None
    id =lambda x: x

    isNone=lambda x: lambda y: None if x==None or y==None else [y]+[x]

    z=Maybe(a).map(isNone(b)).map(isNone(c)).map(lambda x: x-1)
    print(z.join())

    z=Maybe(3).map(isNone(2)).map(isNone(1)).map(lambda x: x)
    print(z.join())

    z=Maybe(3).map(isNone(2)).map(isNone(None)).map(lambda x: x-1)
    print(z.join())
