import Control.Monad.Cont 
import Control.Monad.Fix

getCC :: MonadCont m => m (m a)
-- getCC = callCC (\c -> let x = c x in return x)
getCC = callCC (\c -> return $ fix c)

getCC' :: MonadCont m => a -> m (a, a -> m b)
-- getCC' x0 = callCC (\c -> let f x = c (x, f) in return (x0, f))
getCC' x0 = callCC (\c -> let f x = c (x, f) in return (x0, f))

-- main = (`runContT` return) $
--   do (n, jump) <- getCC' 0
--      lift (print n)
--      jump (n+1)
--
-- main = flip runContT return $ do
--     goto <- getCC :: ContT r m (ContT r m a)
--     lift $ print "hello"
--     goto 
--
--
-- 

repeatIO :: IO () -> IO ()
repeatIO action = 
    flip runContT return $ do { goto <- getCC; lift action; goto }

main = repeatIO (print "hello")


-- main = flip runContT return $ do { goto <- getCC; lift $ print "hello"; goto }


-- return :: a -> m r
-- runContT :: (ContT (a-> m r) -> m r) -> (a -> m r) -> m r
-- m ~ IO
-- this do-notation :: ContT r IO a
-- main :: IO a
-- print n :: IO (), lift IO () into ContT () IO Int 
-- when (n<100) $ jump (n+1) could break this loop

-- https://www.reddit.com/r/haskell/comments/1jk06q/goto_in_haskell/
