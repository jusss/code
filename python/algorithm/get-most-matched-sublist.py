# find the sublist within a list of sublists that has the most elements in common with a given list

# f [1,2,5] [[1,3,6], [1,7], [1,2,3,5]] == [1,2,3,5]

sublists = [[1,3,6], [2,5], [1,2,3,5]]
alist = [1,2,5]

from collections import defaultdict

sublist_count = defaultdict(int)

# since list is not hashable, so use index as key
for n, sublist in enumerate(sublists):
    for a in alist:
        if a in sublist:
            sublist_count[n] = sublist_count[n] + 1

print(sublist_count)

# sort key by value
index = sorted(list(sublist_count.keys()), key=lambda x: sublist_count[x], reverse=True)

result = [sublists[i] for i in index]
print(result)

# may related to longest common substring, BADANAT and CANADAS share the longest string ADA and ANA
# in string, sequence matters, ju to match jumps, not same uj to match jumps
sublists = "the quick brown fox jumps over the lazy dog".split(" ")
alist = "jump"

sublist_count = defaultdict(int)

# since list is not hashable, so use index as key
for n, sublist in enumerate(sublists):
    for a in alist:
        if a in sublist:
            sublist_count[n] = sublist_count[n] + 1

print(sublist_count)

# sort key by value
index = sorted(list(sublist_count.keys()), key=lambda x: sublist_count[x], reverse=True)

result = [sublists[i] for i in index]
print(result)


gpt-4o: Finding the longest common substring (LCS) between two strings is a common problem in computer science. There are several ways to approach this problem, but one of the most efficient methods is using dynamic programming.

Here’s a step-by-step guide to finding the longest common substring using dynamic programming in Python:

### Step-by-Step Guide

1. **Define the Problem**: Given two strings, find the longest substring that appears in both strings.

2. **Dynamic Programming Table**: Create a 2D table where `dp[i][j]` represents the length of the longest common substring ending at `str1[i-1]` and `str2[j-1]`.

3. **Initialization**: Initialize the table with zeros.

4. **Filling the Table**: Iterate through both strings and fill the table based on the following conditions:
   - If `str1[i-1] == str2[j-1]`, then `dp[i][j] = dp[i-1][j-1] + 1`.
   - Otherwise, `dp[i][j] = 0`.

5. **Track the Maximum Length**: Keep track of the maximum length of the common substring found during the iteration.

6. **Extract the Substring**: Use the maximum length and its position to extract the longest common substring from one of the input strings.

### Python Implementation

Here’s the Python code to find the longest common substring using dynamic programming:

```python
def longest_common_substring(str1, str2):
    m = len(str1)
    n = len(str2)

    # Create a 2D array to store lengths of longest common suffixes of substrings
    dp = [[0] * (n + 1) for _ in range(m + 1)]

    # To store the length of the longest common substring
    max_length = 0

    # To store the ending index of the longest common substring in str1
    end_index = 0

    # Build the dp array
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if str1[i - 1] == str2[j - 1]:
                dp[i][j] = dp[i - 1][j - 1] + 1
                if dp[i][j] > max_length:
                    max_length = dp[i][j]
                    end_index = i
            else:
                dp[i][j] = 0

    # The longest common substring
    longest_common_substr = str1[end_index - max_length:end_index]

    return longest_common_substr

# Example usage
str1 = "abcdef"
str2 = "zcdemf"
print("Longest Common Substring:", longest_common_substring(str1, str2))
```

### Explanation

1. **Initialization**: We initialize a 2D list `dp` with zeros. The dimensions of this list are `(m+1) x (n+1)` where `m` and `n` are the lengths of the two input strings.

2. **Filling the Table**: We iterate through each character of both strings. If the characters match, we update the `dp` table and check if the current length of the common substring is greater than the maximum length found so far.

3. **Tracking the Maximum Length**: We keep track of the maximum length of the common substring and the ending index of this substring in `str1`.

4. **Extracting the Substring**: After filling the table, we use the maximum length and the ending index to extract the longest common substring from `str1`.

### Complexity

- **Time Complexity**: \(O(m \times n)\), where \(m\) and \(n\) are the lengths of the two input strings.
- **Space Complexity**: \(O(m \times n)\) for the `dp` table.

This method efficiently finds the longest common substring between two strings using dynamic programming.


------------------------------------

sub = "for"
words = " of the people, for the people, by the people"

p = [ i for i in range(len(words) - len(sub)) if sub[0] == words[i] and sub[1] == words[i+1] and sub[2] == words[i+2] ]
print(p)

p = [ i for i in range(len(words) - len(sub)) if all(sub[z] == words[i+z] for z in range(len(sub))) ]
print(p)

find_string_in_string = lambda sub, words: [ i for i in range(len(words) - len(sub)) if all(sub[z] == words[i+z] for z in range(len(sub))) ]

print(find_string_in_string("e", words))


