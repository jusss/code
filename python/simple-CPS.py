tmp_list = [1,2,3]

compose = lambda f, g: lambda x: f(g(x))
pure = lambda x: lambda f: f(x)

result = [1,2,3,1,2,3,6,2,9]
# result = list(set(result))
# result = list(filter(lambda x: x not in tmp_list, result))
nf = lambda r: filter(lambda x: x not in tmp_list, r)

# one way Compose
# result = compose(list, compose(nf, compose(list, set)))(result)
# list . nf . list . set 

# the second way Promise
#Promise(result).then(set).then(list).then(nf).then(list)

# the third way CPS
#(set)(list)(nf)(list)

result = pure(result)\
        (lambda x: lambda k: k(set(x)))\
        (lambda x: lambda k: k(list(x)))\
        (lambda x: lambda k: k(nf(x)))\
        (lambda x: lambda k: k(list(x)))\
        (lambda x: x)

print(result)
