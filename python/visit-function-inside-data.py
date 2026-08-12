# instead of global var, use a outside object to visit function inside data
# assume function f is defined, now out of f, it need f's inner data, add a new parameter to f to access inner data

outside_new={}
f(a,b,new=outside_new)
outside_new.get('k')

def f(a,b,new:dict={}):
    new['k'] = a+b
