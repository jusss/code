{-# language MultiParamTypeClasses, FunctionalDependencies #-}
{-# language FlexibleInstances #-}
module X where

data T a = V a

class MyT a b | a -> b where
    value :: a -> b

instance MyT (T a) a where
    value (V a) = a

