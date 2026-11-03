def sort_amb(lst):

    result = []

    def amb(new_lst, i, k):
        if i >= len(new_lst):
            return
        cur, rest = new_lst[i], new_lst[:i] + new_lst[i+1:]
        return k(cur, rest, lambda: amb(new_lst, i+1, k))

    def pick(cur, rest, retry):
        if all(cur <= y for y in rest):
            result.append(cur)
            return amb(rest, 0, pick)
        else:
            return retry()

    amb(lst, 0, pick)
    return result

print(sort_amb([3, 3, 1, 2, 2, 1]))
print(sort_amb([5, 2, 8, 1, 9]))
