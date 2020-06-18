import Control.Monad.Trans.Reader

g = do
    x <- (+1)
    y <- (*2)
    return (x + y)  -- return is a function, not a syntax, so it must have () here
main = print $ g 9

-- so we could use record syntax work with Reader
data P a1 a2 a3 = P {runA1 :: a1, runA2 :: a2, runA3 :: a3}

(do  x <- runA1; y <- runA2; z <- runA3; return (x,y,z)) (P 1 "1" 2) == (1,"1",2)


f :: (Show a) => a -> IO ()
-- f x = return x
-- newtype ReaderT r m a = ReaderT { runReaderT :: r -> m a }
-- ReaderT f :: ReaderT a IO ()
f x = print x
-- runReaderT (ReaderT f) == f

-- main =  runReaderT (ReaderT f) "3"
--main = runReaderT (ReaderT print) "3"

--main = runReaderT (ReaderT \x -> do ... ) "3"
--main = flip runReaderT "3" $ ReaderT (\x -> do
-- print x
-- print (x <> "2"))



-- ReaderT print :: Show a => ReaderT a IO ()
    
newtype ReaderT r m a = ReaderT { runReaderT :: r -> m a }

runReaderT . ReaderT = id
runReaderT $ ReaderT f = f

ask :: ReaderT r m r
asks :: (r->a) -> ReaderT r m a
-- <- ask will get r from ReaderT r m a
-- <- asks f will get (f r)

data Environment = Env
  { firstName :: String
  , lastName :: String
  } deriving (Show)

helloworld :: Reader Environment String
helloworld = do
  f <- asks firstName
  l <- asks lastName
  return ("Hello " ++ f ++ l)

runHelloworld :: String
runHelloworld = runReader helloworld $ Env "Jichao" "Ouyang"

data Environment = Env
  { firstName :: String
  , lastName :: String
  } deriving (Show)

t2 :: Environment -> String
-- t2 :: Reader Environment String
t2  = do
  x <- firstName
  y <- lastName
  return $ "Hello " ++ x ++ y

--main = putStrLn (t2 $ Env "John " "Doe")