module ReaderTest where
{-# LANGUAGE FlexibleContexts #-}
import Control.Monad.Reader

data Tree a = Leaf a | Node (Tree a) (Tree a) deriving (Show)
mapTree :: (a->b) -> Tree a -> Tree b
mapTree f (Leaf x) = Leaf (f x)
mapTree f (Node xl xr) = Node (mapTree f xl) (mapTree f xr)

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

t2 :: Environment -> String
--t2 x = "Hello " ++ (firstName x) ++ (lastName x)
--t2 x = ( firstName >>= \x -> lastName >>= \y -> return $ x ++ y ) x
-- the interesting thing here is that \x -> lastName is a binary function, we put a prefix \x -> to an unary, then it's binary now
t2  = do
  x <- firstName
  y <- lastName
  return $ "Hello " ++ x ++ y

--main = putStrLn runHelloworld
main = putStrLn (t2 $ Env "John " "Doe")
       
