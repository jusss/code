from functools import reduce
from operator import add
from itertools import combinations
from copy import deepcopy

sub = "for"
words = " of the people, for the people, by the people"

p = [ i for i in range(len(words) - len(sub)) if sub[0] == words[i] and sub[1] == words[i+1] and sub[2] == words[i+2] ]
print(p)

p = [ i for i in range(len(words) - len(sub)) if all(sub[z] == words[i+z] for z in range(len(sub))) ]
print(p)

find_string_in_string = lambda sub, words: [ i for i in range(len(words) - len(sub)) if all(sub[z] == words[i+z] for z in range(len(sub))) ]

print(find_string_in_string("e", words))
