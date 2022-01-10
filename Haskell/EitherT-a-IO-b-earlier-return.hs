import Control.Monad.Trans.Except
import Control.Monad.IO.Class

f :: Int -> ExceptT () IO Int

f x = do

  if x>3 then do

    liftIO $ print "greater than 3"

    ExceptT $ fmap Left $ print x

  else do

    liftIO $ print x

    return x

r = traverse f [1..6]

main = runExceptT r


-- data ExceptT a m b = ExceptT m (Either a b)
-- since there's no IOT, use fmap to constructor IO m a in ExceptT a IO b
