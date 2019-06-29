class Test:
    def __init__(self):
          self.attb = 'whatever'
          self.atta = 'aha'
    @classmethod
    def changeAttrB(cls,x):
        tt=cls()
        tt.attb=x
        return tt

    def run(self):
        print(self.atta)
        print(self.attb)

t=Test.changeAttrB(3)
t.run()
