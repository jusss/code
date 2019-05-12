import Control.Applicative
import Control.Monad
data T a = V a deriving (Show)
instance Functor T where
 fmap f (V x) = V (f x)
instance Applicative T where
 pure = V
 (V f) <*> (V x) = V (f x)
instance Monad T where
 return x = V x
 (V x) >>= f = f x

-- T-Monad.hs
-- Prelude> :l T-Monad
-- fmap (\x -> x + 1) (V 3)
-- V (\x -> x + 1) <*> V 3
-- V 3 >>= return 
-- V 3 >>= \x -> return (x + 1)
-- return 3 >>= \x -> V (x + 1)

