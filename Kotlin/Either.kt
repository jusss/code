// Look its type, there's no magic in FP

if (a != null) {
    var b = getMoreData(a)
    if (b != null) {
        var c = getMoreData(b)
        if (c != null) {
            getMoreData(a+b+c)
        }
    }
}

val result = Either.right(a)
    .flatMap { a -> if (a) Either.right(getMoreData(a)) else Either.left("null") }
    .flatMap { b -> if (b) Either.right(getMoreData(b)) else Either.left("null") }
    .flatMap { c -> if (c) Either.right(getMoreData(a+b+c)) else Either.left("null") }

fun f(g: (A) -> B, x: A): Either<Sting,B> = if (x) Either.right(g(x)) else Either.left("null")

// the return type B must show up in parameters, it can't be unknown
// f :: a -> b isn't ok, but f :: a -> a is ok, the previous b is unknown
// a is a type variable, it can be any type, concrete by parameter 
// Any can be any type, I don't know if it's concreted by parameter,'cause type erase 
// but Any as result type, it still can return any type, just like dynamic type languages
// A as result type, it can't be any type, it's concreted by parameters
// there's no null and Any in Haskell
// Haskell's type variables are concreted by parameters, not like Any in Kotlin, Object in Java
// bottom value _ is just a magic stuff in GHC, not in Haskell, not like null in Kotlin

val result = Either.right(a)
    .flatMap { a -> f(getMoreData,a)} //don't ignore a here is for using a in the rest
    .flatMap { b -> f(getMoreData,b)}
    .flatMap { c -> f(getMoreData,(a+b+c))}

// do-notation
val result = Either.fx {
    val b = f (getMoreData,a)
    val c = f (getMoreData,b)
    f (getMoreData,(a+b+c))
}

// flatMap can do if-else, return left or right, map can't, 
// map use (a -> b), flatMap use (a -> m b)
// map's benifit is f needn't know the monad, f can be generics
// flatMap can do if-else, but f need to declare the monad type to return, f need to be concreted
// div3 x = 3/x
// Just 0 <$> div3 == Just Infinity
// Just 0 >>= \x -> if (x == 0) then Nothing else return (div3 x)

-----------------------------------------------------------------
https://philipnilsson.github.io/Badness10k/escaping-hell-with-monads/

var a = getData();
if (a != null) {
  var b = getMoreData(a);
  if (b != null) {
     var c = getMoreData(b);
     if (c != null) {
        var d = getEvenMoreData(a, c)
        if (d != null) {
          print(d);
        }
     }
  }
}

var a = getData();
var b = a?.getMoreData();
var c = b?.getMoreData();
var d = c?.getEvenMoreData(a);
print(d);

-- in do-notation, the right side of <-, it must be (m a) to fit do-notation
-- Either or Maybe can't detect Error automatically, you need to detect it
-- use detect before run to prevent runtime error
-- that's what Either to do instead of capture runtime Exception(try-catch)
-- there's no magic in FP

-- getMoreData type must be getMoreData :: a -> Maybe a, so it maybe Nothing here
do
  a <- getData
  b <- getMoreData a
  c <- getMoreData b
  d <- getEvenMoreData a c
  print d
