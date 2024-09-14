d = {"a":2, "b":1, "c":3}
# sorted, first parameter is object you want to sort, second is lambda x, x is the item of the first
d2 = sorted(list(d.keys()), key=lambda x: d[x], reverse=True)
# d2 == ['c', 'a', 'b']
print(d2)

