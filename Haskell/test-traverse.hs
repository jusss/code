
import Control.Monad.Trans.State
import Control.Monad.Trans.Class (lift)
import Data.Foldable (traverse_)
import Data.Maybe (fromMaybe)
-- rec :: [Double] -> ([Double] -> State [Double] c) -> State [Double] c
-- rec ls k = mapK (\x c -> if x == 0
    -- then k [x]
    -- else do
        -- modify (1/x:)
        -- c (1/x)) ls k

-- -- Running the `rec` function and extracting results
-- main :: IO ()
-- main = do
    -- let input = [1, 2, 3, 0, 4]
        -- k = \x -> return x
        -- (result, state) = runState (rec input k) []
    -- print result



f 0 = Nothing
f x = Just (1 / x)

result :: StateT [Double] Maybe [Double]
result = traverse (\x -> do
            if x == 0
                then lift Nothing  -- Fail the computation by lifting Nothing into StateT
                else do
                    modify (1/x:)    -- Update the state with 1/x
                    return (1 / x) -- Return 1/x as the result
         ) [1, 2, 3, 0, 4]


main = print $ runStateT result []


--main = print $ traverse (\x -> if x == 0 then Nothing else Just (1/x)) [1,2,3,0,4]
