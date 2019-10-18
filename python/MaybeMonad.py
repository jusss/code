class Maybe:
    def __init__(self,value):
        self.value=value

    def of(self,value):
        return Maybe(value)

    def isNone(self):
        return True if self.value==None else False

    def map(self,f):
        if self.isNone():
            return self.of(None)
        return self.of(f(self.value))

    def join(self):
        return self.value

    def isNone2(self,v):
         if self.value == None:
             return self.of(None)
         if v ==None:
             return self.of(None)
         else:
             return self.of([self.value,v])
    """
    def isNone2(self,v):
        self.map
    """
    def id(self,a):
        return a
    

id = lambda x: x


"""
if a!=None:
  if b!=None:
   if c!=None:
     doSomething
"""
z=Maybe(3).isNone2("ok").isNone2(1).map(id)
print(z.join())

"""
if a!=None:
  if f(a)!=None:
    if g(f(a))!=None:
      doSomething
"""
z= Maybe(None).map(id).map(id)
print(z.join())

z= Maybe(3).map(id).map(id)
print(z.join())

"""
if a!=None:
    if b!=None:
        return 1
    else:
        return 2
        if c!=None:
            return 3
        else:
            return 4
else:
    return 5
"""

