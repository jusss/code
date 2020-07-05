
data Tree a = Leaf | Node a (Tree a) (Tree a) deriving (Show)

instance Functor Tree where
    fmap f Leaf = Leaf
    fmap f (Node a l r) = Node (f a) (fmap f l) (fmap f r)

x :: Tree Int
x = Node 0 (Node 1 (Node 3 Leaf Leaf) (Node 4 Leaf Leaf)) (Node 2 Leaf Leaf)

main = print $ fmap (+1) x
-- Node 1 (Node 2 (Node 4 Leaf Leaf) (Node 5 Leaf Leaf)) (Node 3 Leaf Leaf)


getNode :: Num a => Tree a -> [a]
getNode Leaf = [0]
getNode (Node a l r) = [a] <> (getNode l) <> (getNode r)

-- main = print $ getNode x
main = print . sum . getNode $ x


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



        0
       / \
      1   2
     / \ / \
    3  4 5 6

this data type can express lke

    data Tree a = Leaf | Node a (Tree a) (Tree a)

so that is Node 0 (Node 1 (Node 3 Leaf Leaf) (Node 4 Leaf Leaf)) (Node 2 (Node 5 Leaf Leaf) (Node 6 Leaf Leaf))

    instance Functor Tree where
        fmap :: (a -> b) -> Tree a -> Tree b
        fmap f Leaf = Leaf
        fmap f (Node a l r) = Node (f a) (fmap f l) (fmap f r)

also if you want three branches it would be 

    data Tree a = Leaf | Node a (Tree a) (Tree a) (Tree a)

if we want to get the sum of number, make it as an instance of Foldable, implement sum
if you want every element plus 1, make it as instance of Functor, implement fmap
if you want to operate on two those trees, make it as instance of Applicative, implement liftA2

there're more than one tree,

    data Tree a = Leaf a | Node (Tree a) (Tree a)

          0
           \ 
            1
           / 
          2
           \ 
            3
           / \
          4   5
                         
 
            
    data Tree a = Leaf a | Node a (Tree a) (Tree a)
this would force every node to have two populated descendents, it can't represent trees with odd numbers
https://stackoverflow.com/questions/41408922/data-type-for-tree-in-haskell
http://learnyouahaskell.com/zippers

