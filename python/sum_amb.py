# sum three number to zero
def sum_amb(lst):

    result = []

    def amb(i, ii, k):
        if i > len(lst)-3:
            return

        if ii > len(lst)-3-i:
            return amb(i+1,0,k)

        return k(i,ii, lambda: amb(i,ii+1,k))

    def pick(i,ii, retry):
        if lst[i] + lst[i+1] + lst[i+2+ii] == 0:
            result.append([lst[i] , lst[i+1] , lst[i+2+ii]])
            return amb(i,ii+1,pick)
        else:
            return retry()

    amb(0,0, pick)
    return result

print(sum_amb([3, 3, -1, -2, -2, 1,4]))
