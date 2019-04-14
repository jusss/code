class Promise:
    def __init__(self,_value):
        self.value = _value

    def then(self,func):
        try:
            return Promise(func(self.value))
        except Exception as e:
            return e

    def join(self):
        return self.value

n = Promise(5).then(lambda x: x+2).then(lambda x: x+3).join()
print(n)
