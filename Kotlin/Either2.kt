sealed class Either<A,B>
data class Left<A,B>(val v:A):Either<A,B>()
data class Right<A,B>(val v:B):Either<A,B>()

fun  test(e: Either<Int,String>):Any{
    when (e){
         is Left<Int,String> -> return e.v
         is Right<Int,String> -> return e.v
    }
}

fun <A,B> test2(e:Either<A,B>){
    when (e){
        is Left<A,B> -> e.v //return e.v then test2 return A, and return e.v on Right will return B, and Any is not ok here, 'cause A and B are not concret
        is Right<A,B> -> e.v //so don't use return, will return Unit
    }
}

fun main(){
    val t = Left<Int,String>(3)
    println(t.v)
    val t2 = test(Left<Int,String>(3))
    println(t2)
}

fun <A> t(e:A){
    //e.length
}
fun t2(e:String){
    e.length
}