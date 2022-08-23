from unwrapped_type import *

k = return_cont(3)
# print(k(identity))



# Prelude> import Control.Monad.Trans.Cont
# Prelude Control.Monad.Trans.Cont> k = return 3
# Prelude Control.Monad.Trans.Cont> k2 = k >>= \a -> return (a+1)
# Prelude Control.Monad.Trans.Cont> runCont k2 id
# 4
# Prelude Control.Monad.Trans.Cont> 

# why not cont.bind? and make bind_cont using infix is import to intuition
cps = bind_cont(k, lambda a: return_cont(a+1))
# print(cps(identity))
# print(cps(lambda x: "b"))

cps_2 = bind_cont(cps, lambda x: return_cont(x+2))
# print(cps_2(identity))

# circuit
cps_3 = bind_cont(k, (lambda a: bind_cont(lambda b: a, lambda c: return_cont(c))))
# print(cps_3(identity))

# cps_4 = bind_cont(k, (lambda a: bind_cont(lambda b: return_cont(a+3), lambda a_: return_cont(a_))))
# print(cps_4(identity))


cps_5 = bind_cont(k, lambda a: bind_cont(return_cont(a+1), lambda b: return_cont(a+b)))
# print(cps_5(identity))

def circuit(x,y):
    if x==y:
        return lambda z: x
    else:
        return return_cont(x)

# circuit
# cps_6 = bind_cont(k, lambda a: bind_cont(circuit(a,3), lambda b: return_cont(a+b)))
cps_6 = bind_cont(k, lambda a: bind_cont(lambda z: a if a == 3 else return_cont(z), lambda b: return_cont(a+b)))
# print(cps_6(identity))

# Playing with Multiple Callback Invocations
cps_7 = bind_cont(k, lambda a: bind_cont(lambda x: x("a") + x("b"), lambda b: return_cont(str(a)+b)))
print(cps_7(identity))




