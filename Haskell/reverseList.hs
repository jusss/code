reverse_ l = let
    _reverse (x:xs) y = _reverse xs (x:y)
    _reverse [] y = y
    in _reverse l []


{- main = print $ _reverse [1..6] [] -}
main = print $ reverse_ [1..6]
