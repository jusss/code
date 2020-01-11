import Control.Monad.Trans.Maybe
import Control.Monad.IO.Class

main = runMaybeT $ (liftIO ((print $ 3) :: IO ()) :: MaybeT IO ())

-- print $ Just 3 :: IO ()
-- liftIO (print $ Just3) :: m () 
-- m ~ MaybeT IO
-- m () ~ MaybeT IO ()
-- liftIO :: IO a -> m a 
-- newtype MaybeT m a = MaybeT { runMaybeT :: m (Maybe a) }
