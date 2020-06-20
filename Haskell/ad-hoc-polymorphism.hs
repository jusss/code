{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}

class IS a where { f :: a -> a}
instance IS Int where { f = (+1) }
instance IS String where
    f = reverse

main = print $ (f (2 :: Int), f "23")
