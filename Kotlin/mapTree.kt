sealed class Tree<T>
data class Node<T>(val left: Tree<T>, val right: Tree<T>): Tree<T>()
data class Leaf<T>(val value: T): Tree<T>()

fun <T,R> Tree<T>.map(transform: (T) -> R): Tree<R> {
    return when (this) {
        is Node -> Node(
            left = left.map(transform),
            right = right.map(transform)
        )
        is Leaf -> Leaf(transform(value))
    }
}

fun main(){
    val tree = Node(Leaf(1), Node(Leaf(2), Leaf(3)))
    val mapped = tree.map { it * it }
    println(mapped)
}

//data Tree a = Leaf a | Node (Tree a) (Tree a)
//            deriving (Show)
//
//maptree :: (a->b) -> Tree a -> Tree b
//maptree f (Leaf a) = Leaf (f a)
//maptree f (Node xl xr) = Node (maptree f xl) (maptree f xr)
//
//Prelude> maptree (+1) (Node (Leaf 2) (Node (Leaf 5) (Leaf 9)))
//Node (Leaf 3) (Node (Leaf 6) (Leaf 10))
