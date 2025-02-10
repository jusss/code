mapK :: (a -> (b -> c) -> d) -> [a] -> (b -> c) -> d
mapK _ [] k = k []
mapK p (x:xs) k = p x (\v -> mapK p xs (\ns -> k (v:ns)))

rec :: [Double] -> (b -> c) -> c
rec [] k = k []
rec (x:xs) k = 
    if x == 0 
    then mapK (\x c -> k [x]) [x] k 
    else rec xs k >> (if x /= 0 then 1 / x else 0) `seq` k [1 / x]

main :: IO ()
main = do
    let result = []
    let ls = [1.0, 2.0, 3.0, 0.0, 4.0]
    print (rec ls (\x -> x))
    -- In Haskell, we don't have a direct equivalent of modifying a global list like in Python.
    -- So, this part is not straightforward to translate.
    -- If you have a specific use case or a way you'd like to handle the "result" list in Haskell,
    -- it would be helpful to know more details to provide a more accurate translation.

