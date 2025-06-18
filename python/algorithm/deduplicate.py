remove_duplicate= lambda ns: [ns[n] for n in range(len(ns)) if ns[n] not in ns[:n]]
remove_duplicate([4, 4, 3, 4, 6, 4, 6, 9, 3, 1, 7, 4, 9, 8, 4, 1, 2, 4, 5, 10])
[4, 3, 6, 9, 1, 7, 8, 2, 5, 10]
