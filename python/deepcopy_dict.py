from copy import deepcopy

# since dict is an object, and list.append on object, it always will be the last modified object, so use deepcopy to avoid that by create a new one
# alter the new one won't affect the original one

v={"a":1, "c":[1,2,3]}
fs = []
for i in range(len(v["c"])):
    v1 = deepcopy(v)
    v1["a"] = v["c"][i]
    fs.append(v1)

print(fs)
