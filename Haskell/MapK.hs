
import Control.Monad.Trans.State
import Control.Monad.Trans.Class (lift)
import Data.Foldable (traverse_)
import Data.Maybe (fromMaybe)

-- mapK p [] accum k = k []
-- mapK p (x: xs) accum k = p x $ \v -> mapK p xs (v: accum)   $ \ns -> k (v: ns)

-- main = print $ mapK (\x -> \c -> if x == 0 then k accum else c (1/x)) [1,2,3,0,4] [] id

-- alist = []
-- for i in range(3):
  -- alist.append(i)


mapK p [] k = k []
mapK p (x: xs) k = p x $ \v -> mapK p xs $ \ns -> k (v: ns)

--rec = \ls -> \k -> mapK (\x -> \c -> if x == 0 then k [x] else c (1/x)) ls k
rec = \ls -> \k -> mapK (\x -> \c -> if x == 0 then mapK  (\x c -> k [x]) [x] k else c (1/x)) ls k

-- main = print $ mapK (\x -> \k -> k (x+1)) [1..9] $ fmap (+2)
main = print $ rec [1,2,3,0,4] id
--main = print $ mapK (\x -> \c -> if x == 0 then id [x] else c (1/x)) [1,2,3,0,4] id

-- (\x -> \k -> k (x+1)) 1 $ \v -> mapK p [2..9] $ \ns -> fmap (+2) (v: ns)
-- \k -> k 2 $ \v -> \k -> k 3 $ \v -> ...


-- main = print $ traverse (\x -> if x == 0 then Nothing else Just (1/x)) [1,2,3,0,4]
-- mapK can do same thing like traverse, they both can do eary return, but not return with previous accumlated result
-- use State or recursive function to store previous result? run traverse in StateT s Maybe a?
--
--

-- result :: StateT s Maybe a
-- result = do
    -- lift $ traverse (\x -> if x == 0 then Nothing else do
        -- put Just (1/x)
        -- Just (1/x)
        -- ) [1,2,3,0,4]

-- main = print $ runStateT result 9


-- result :: StateT Double Maybe [Double]
-- result = traverse (\x -> do
            -- if x == 0
                -- then lift Nothing  -- Fail the computation by lifting Nothing into StateT
                -- else do
                    -- put (1 / x)    -- Update the state with 1/x
                    -- return (1 / x) -- Return 1/x as the result
         -- ) [1, 2, 3, 0, 4]

-- main = print $ runStateT result 9
