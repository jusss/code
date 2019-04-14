module Test  where

findKey :: (Eq k) => k -> [(k,v)] -> Maybe v
findKey key [] = Nothing
findKey key ((k,v):xs) 
    | key == k = Just v
    | otherwise = findKey key xs


             
