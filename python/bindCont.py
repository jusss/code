ret = lambda val: lambda out: out(val)
twoC = ret(2)
bind = lambda inC, fn: lambda out: inC(lambda inCval: fn(inCval)(out))
bind(twoC, lambda two: ret(two*2))(lambda x: x)
bind(twoC, lambda two: ret(3))(lambda x: x)
bind(twoC, lambda two: ret(two*2))(lambda x: x)
bind(twoC, lambda two: bind((lambda out: out(two)), lambda hello: ret(hello+1)) )(lambda x: x)
3
bind(twoC, lambda two: bind((lambda out: "boom!"), lambda hello: ret(hello+1)) )(lambda x: x)
'boom!'
