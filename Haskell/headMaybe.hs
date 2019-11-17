headMaybe :: [a] -> Maybe a
headMaybe [] = Nothing
headMaybe (x:xs) = Just x

tailMaybe :: [a] -> Maybe a
tailMaybe [] = Nothing
tailMaybe xs = headMaybe $ reverse xs


