import Control.Monad (when)
import Control.Monad.Trans.State

import Control.Monad.Trans.Class (lift)
import Control.Monad.Trans.Cont


-- mapK function
mapK :: ((a -> (b -> State [Double] c) -> State [Double] c)) -> [a] -> ([b] -> State [Double] c) -> State [Double] c
-- mapK :: (a -> ContT c (State [Double]) b) -> [a] -> ContT c (State [Double]) [b]
mapK _ [] k = k []
mapK p (x:xs) k = p x (\v -> mapK p xs (\ns -> k (v : ns)))

-- Recursive function using mapK
-- turn this rec to ContT
rec :: [Double] -> ([Double] -> State [Double] c) -> State [Double] c
-- rec :: [Double] -> ContT c (State [Double]) [Double]
rec ls k = mapK (\x c -> if x == 0
    then k [x]
    else do
        modify (1/x:)
        c (1/x)) ls k

-- Running the `rec` function and extracting results
main :: IO ()
main = do
    let input = [1, 2, 3, 0, 4]
        k = \x -> return x
        (result, state) = runState (rec input k) []
    print result
    print state


-- -- mapK function using ContT and State
-- mapK :: (a -> ContT c (State [Double]) b) -> [a] -> ContT c (State [Double]) [b]
-- mapK _ [] = return []
-- mapK p (x:xs) = do
    -- v <- p x
    -- vs <- mapK p xs
    -- return (v:vs)

-- -- Recursive function using mapK and ContT
-- rec :: [Double] -> ContT c (State [Double]) [Double]
-- rec ls = mapK (\x -> ContT $ \k ->
    -- if x == 0
    -- then k [x]
    -- else do
        -- lift $ modify (1/x :)
        -- k (1/x)) ls

-- -- Running the `rec` function and extracting results
-- main :: IO ()
-- main = do
    -- let input = [1, 2, 3, 0, 4]
        -- initialState = []
        -- (result, state) = runState (runContT (rec input) return) initialState
    -- print result
    -- print state
