from Maybe import *
foo= Just("3").bind(lambda x:
               (Nothing.bind(lambda y:
                               Just(x+y))))
print(foo.join())
print(foo.mempty)

addM = lambda mx,my: mx.bind(lambda x:  my.bind(lambda y: mx.unit(x+y)))

bar = addM(Just(3), Just(9))
print(bar.join())
