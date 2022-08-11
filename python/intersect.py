from functools import reduce
intersect = lambda xxs: list(reduce(lambda xs, ys: [x for x in xs if x in ys], xxs))

print(intersect([[1,2,3],[3,4,23],[7,8,2,3,56]]))
