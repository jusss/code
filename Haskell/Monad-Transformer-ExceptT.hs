{-# LANGUAGE ScopedTypeVariables #-}
import Control.Monad.Trans.Except
import Control.Monad.IO.Class
main = do
    -- ExceptT String IO Int; only run IO on Right way
    -- return Left a will short circuiting computation and will get Left a
    r :: Either String () <- runExceptT $ do
        -- return construct IO a
        a <- ExceptT (return $ Right 3 :: IO (Either String Int))
        -- Left "a" won't run
        -- a <- ExceptT (return $ Left "a" :: IO (Either String Int))
        -- run IO inside Either, not need to wait Either's result to run IO
        liftIO $ print a
    print r
    return ()
