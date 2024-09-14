from collections import defaultdict

# find the sublist within a list of sublists that has the most elements in common with a given list
# f [1,2,5] [[1,3,6], [1,7], [1,2,3,5]] == [1,2,3,5]

def get_most_matched_sublist(alist, sublists):
    sublist_count = defaultdict(int)

    # since list is not hashable, so use index as key
    for n, sublist in enumerate(sublists):
        for a in alist:
            if a in sublist:
                sublist_count[n] = sublist_count[n] + 1
    
    # sort key by value
    index = sorted(list(sublist_count.keys()), key=lambda x: sublist_count[x], reverse=True)
    
    result = [sublists[i] for i in index]
    print(result)
    return result

get_most_matched_sublist([1,2,5], [[1,3,6], [2,5], [1,2,3,5]])
