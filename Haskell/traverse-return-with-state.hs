import Control.Monad.Trans.Maybe
import Control.Monad.Trans.State
import Control.Monad.Trans.Class (lift)
import Data.Foldable (traverse_)
import Data.Maybe (fromMaybe)

--main = print $ traverse (\x -> if x == 0 then Nothing else Just (1/x)) [1,2,3,0,4]

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

action:: MaybeT (State Int) ()
action = do
    lift (modify (+1))
    MaybeT (return Nothing)
    lift (modify (+1))
    
--main = print $ execState (runMaybeT action) 1

f 0 = Nothing
f x = Just (1 / x)

result = traverse (\x -> do
            if x == 0
                then MaybeT $ return Nothing  
                else do
                    lift $ modify (1/x:)
                    return (1 / x)
         ) [1, 2, 3, 0, 4]

-- main = print $ runState (runMaybeT result) []
main = print $ execState (runMaybeT result) []

-- from deepseek R1, traverse (\x -> if x == 0 then Nothing else Just (1/x)) [1,2,3,0,4] will get Nothing,
-- how to accumulated the values like [1.0, 0.5, 0.333] before meet 0
-- maybe we can model this with StateT, where the base monad is Maybe, so the StateT s Maybe a monad allows
-- stateful computation that can fail with Nothing. but then how do we collect the list up to that point
-- because once the computation fails, the state might not be accessible anymore
-- why once the computation fails, the state not be accessible anymore
-- state allows threading state through computation, but when combined with Maybe, any failure (Nothing) would
-- short-circuit the entire computation, once a Nothing is encountered, the processing stops, and the state up
-- to that point is retained, 
-- monad transformer layers matter. if you have StateT s Maybe, then the state is preserved even if the computation
-- fails with Nothing, but if you have MaybeT (State s), then when the maybe fails, MaybeT (State s) would run the 
-- State computation
-- action :: StateT Int Maybe ()
-- action = do
--  modify (+1)
--  lift Nothing
--  modify (+1)
-- if we run runStateT action 0, it will execute the first modify then lift Nothing, we don't get state
-- use StateT s Maybe a, one step fails, lose both the result and state
-- in contrast, MaybeT (State s) a is equivalent to State s (Maybe a). even if the computation inside returns Nothing
-- the state changes up to that point are retained
-- action:: MaybeT (State Int) ()
-- action = do
--     lift (modify (+1))
--     MaybeT (return Nothing)
--     lift (modify (+1))
-- Running runMaybeT action and then execState would give us the state after the first modify, because the second modify is 
-- never reached. So the state is 1, and the result is Nothing.
-- So the order of the monad transformers matters, if you want to accumulate state even after a failure, you need MaybeT (State s), but if you use StateT s Maybe, the state is lost on failure.
--
-- StateT (s -> m (a, s)) :: StateT s m a
-- runStateT :: StateT s m a -> s -> m (a, s), so runStateT (x :: StateT s Maybe a) (inital:: s) :: Maybe (a,s)
-- if it's Nothing, then no state can be accessible
-- runMaybeT :: MaybeT m a -> m (Maybe a), so runMaybeT (x:: MaybeT (State s) a) :: State s (Maybe a),
-- runState (x:: State s (Maybe a)) :: s -> (Maybe a, s),   so it will get result Maybe a, and state
