-- there's a list [1,2,[3,4],[3,[5,6,[7]]]], who to let every element in it plus 1?
-- <Cale> jusss`: All the elements of a Haskell list must have the same type
-- <Cale> jusss`: If we want a tree, we'll use a tree data type

data Tree a = Nil | Cons a (Tree a) | Subtree (Tree a) (Tree a) deriving (Show)

v :: Tree Int
v = Cons 1 (Cons 2 (Subtree (Cons 3 (Cons 4 Nil)) (Subtree (Cons 3 (Subtree (Cons 5 (Cons 6 (Subtree (Cons 7 Nil) Nil))) Nil)) Nil)))

instance Functor Tree where
    fmap f = g
        where
            g Nil = Nil
            g (Cons x t) = Cons (f x) (g t)
            g (Subtree t t') = Subtree (g t) (g t')

main = print $ fmap (+1) v

-- Cons 2 (Cons 3 (Subtree (Cons 4 (Cons 5 Nil)) (Subtree (Cons 4 (Subtree (Cons 6 (Cons 7 (Subtree (Cons 8 Nil) Nil))) Nil)) Nil)))

--data Tree a = Leaf a | Node (Tree a) (Tree a) deriving (Show)
--mapTree :: (a->b) -> Tree a -> Tree b
--mapTree f (Leaf x) = Leaf (f x)
--mapTree f (Node xl xr) = Node (mapTree f xl) (mapTree f xr)
