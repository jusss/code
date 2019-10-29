module SplitList where
-- main = print $ splitList [1,2,3,2,4,5] [4,5] 
-- [1,2,3,2,4,5] [3,4] == []
-- [1,2,3,2,4,5] [1,2] == [[],[3,2,4,5]]
-- [1,2,3,2,4,5] [4,5] == [[1,2,3,2],[]]
splitList listA listB = f listA listB [] 0
      where
           lengthB = lengthList listB
           copyB = listB
           
           f (x:listA) [] before counter =
                     if (counter == lengthB) then (reverse $ removeN before lengthB):(x:listA):[]
                     else f listA copyB (x:before) 0

           f [] listB before counter =
                   if (null listB) && (counter == lengthB) then (reverse $removeN before lengthB):[]:[]
                   else []
                   
           f (x:listA) (y:listB) before counter =
                         if (x == y) then f listA listB (x:before) (counter+1)
                         else f listA copyB (x:before) 0
                     
removeN :: [a] -> Int -> [a]
removeN = \alist n ->
        if (n == 0) then
           alist
           else
           removeN (tail alist) (n - 1)

lengthList :: [a] -> Int
lengthList alist = f alist 0
           where
                f [] n = n
                f (x:xs) n = f xs (n+1)


  
