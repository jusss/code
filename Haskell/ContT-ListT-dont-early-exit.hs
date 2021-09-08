import Control.Monad
import Control.Monad.Trans.Cont
import Control.Monad.Trans.Class
import Control.Monad.Trans.State
import Data.Foldable

result alist = flip runContT pure $ do
    r <- lift alist
    if (r == 3) then pure 2 
    else pure r

-- main =  print $ result [1..6]

-- newtype ContT r m a = ContT { runContT :: (a -> m r) -> m r }

ee :: [Int] -> ContT Int [] Int
ee alist = do
    r <- lift alist
    return r

ee2 :: [Int] -> ContT Int [] Int
ee2 alist = callCC $ \k -> do
    r <- lift alist
    if (r == 3) then ContT $ \k -> [2]
    else return r

-- main = print $ runContT (ee2 [1..6]) return

ee3 alist = flip runContT return $ do
    r <- lift alist
    if (r == 3) then return 2
    else return r

--main = print $ ee3 [1..6] -- [1,2,2,4,5,6], could it just return [1,2]?

-- no, because ContT Int [] Int can't do early exit, it can't break a list
-- ListT or LogicT could break a list, but ListT doesn't exist
-- if ListT exist, we can lift print every element inside it without sequence
-- ListT isn't a proper monad, List monad doesn't short circuit the way you think
-- continuation monad on top of the list monad is madness...
--

main = print $ flip runStateT [] $ for_ [1..] $ \x -> do
    xs <- get
    if x > 5 then lift $ Left xs
    else put (x:xs)
-- Left [5,4,3,2,1]

    
    
