import Control.Monad.Trans.Except
import Control.Monad.Trans.Cont
import Control.Monad.Trans.Class
import Control.Monad.IO.Class

-- runExceptT :: ExceptT r m a -> m (Either r a)
-- ExceptT $ m (Either r a) :: ExceptT r m a
-- runContT :: ContT r m a -> (a -> m r) -> m r
-- ContT $ (a -> m r) -> m r :: ContT r m a
--
-- ExceptT $ ContT $ (\k -> k (Right ())) :: ExceptT e (ContT r m) ()
-- (ExceptT . ContT) (\k -> k (Right ())) :: ExceptT e (ContT r m) ()
-- runExceptT . ExceptT :: m (Either e a) -> m (Either e a)
-- v = (ExceptT . ContT) (\k -> k (Right ()))
-- (runContT . runExceptT) v print
--
-- how to construct a value which has ExceptT r (ContT r IO) a?
-- ExceptT $ (ContT r IO) (Either r a)
-- ExceptT $ ContT r IO (Either r a)
-- ExceptT $ ContT $ (Either  r a -> IO r) -> IO r
-- ExceptT $ ContT $ \(k :: Either r a -> IO r) -> k (v :: Either r a)

-- 1. ExceptT $ ContT $ \(k :: Either r a -> IO ()) -> k (v :: Either r a)
-- 2. (lift . lift) (v :: IO a)
-- 3. lift $ ContT $ \k -> (k a :: IO a)
-- lift must work on k a, not k $ Either r a, unless it's ContT short circuit
-- those form can be constructed in ExceptT r (ContT () IO) a
-- Either effect only run the Right way, can use 1 to construct
-- IO effect can use liftIO to construct
-- Cont effect can use 1 or 3 to construct, also lift $ ContT $ \k -> return $ Right () :: IO (Either String ()) can short circuit

diveBy a 0 = Left "dive by zero"
diveBy a b = Right $ a/b

-- do notation take monad's position, runExceptT $ ExceptT (return $ Right 3), then runExceptT $ do

main = ((flip runContT return) . runExceptT) $ do

    -- Either effect only run Right way
    a <- (ExceptT . ContT) (\k -> k (Right 1))
    -- a <- (ExceptT . ContT) (\k -> k (diveBy 3 1))
    -- a <- (ExceptT . ContT) (\k -> k (diveBy 3 0))

    -- ContT effect take a continuation
    -- Note that the argument to `lift` has type `Num a => ContT r m a`. The `lift` call, using `instance MonadTrans (ExceptT e)`, is turning it from `Num a => ContT r m a` into `Num a => ExceptT e (ContT r m) a`
    -- If you replace `k 2` with a type hole `_`, GHC says its type is `IO (Either e ())` and that the type of `k` is `a0 -> IO (Either e ())` <- note that `k` is creating the `Either` for us
    -- why? `lift` is not just the constructor: https://hackage.haskell.org/package/transformers-0.5.6.2/docs/src/Control.Monad.Trans.Except.html#line-249
    b <- lift $ ContT $ \k -> k 2

    -- ContT effect short circuit, so no need to liftIO $ print c
    -- c <- lift $ ContT (\k -> ( return $ Right () :: IO (Either String ()) ))
    -- c <- ExceptT $ ContT $ \k -> ( return $ Right () :: IO (Either String ()) )

    -- lift IO Int into ContT then lift into ExceptT
    e <- (lift . lift) (return $ 6 :: IO Int)

    -- IO effect
    liftIO $ print a
    liftIO $ print b
    liftIO $ print e
