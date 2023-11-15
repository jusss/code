import Control.Monad.Trans.Reader
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Data.Map

data Env = Env { getName :: String, getAge :: Int }
env = Env "Peter" 30

env2 = fromList [("Peter", 30), ("Tom", 32)]

f :: Env -> IO ()
f env = do
    print $ getName env

g :: Env -> IO ()
g env = do
    print $ getAge env

h :: String -> Map String Int -> IO ()
h name _map = print $ _map ! name

-- data ReaderT r m a = ReaderT { runReaderT :: r -> m a }

-- main = flip runReaderT env $ do
    -- ReaderT f
    -- ReaderT g

main = flip runReaderT env2 $ do
    ReaderT $ h "Peter"
    ReaderT $ h "Tom"

-- Reader is just the last parameter placeholder, Reader need every single function defined with that r from Reader r a as the last parameter,
-- so you can hide the last parameter, very strict or limited
