import Data.List
main = print $ ((sort .) . (<>)) [1..5] [2..7]
