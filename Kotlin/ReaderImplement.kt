class Reader<D, out A>(val run: (D) -> A) {

    inline fun <B> map(crossinline  fa: (A) -> B): Reader<D, B> = Reader {
        d -> fa(run(d))
    }

    inline fun <B> flatMap(crossinline  fa: (A) -> Reader<D, B>): Reader<D, B> = Reader {
        d -> fa(run(d)).run(d)
    }


    companion object Factory {
        fun <D, A> just(a: A): Reader<D, A> = Reader { _ -> a }

        fun <D> ask(): Reader<D, D> = Reader { it }
    }
}

fun main () {
    val add1 = {x: Int -> x+1}
    val mul3 = {x: Int -> x*3}
    val reader = Reader(add1).map(mul3)
    println(reader.run(3))
    val y = Reader.ask<M>().map {it.x + 2
    }
    println(y.run(M(9)))  // it's just define f(obj: M) then handle obj.x inside f, and then call f(M(newX))



}

data class M(val x: Int =3)

// https://jorgecastillo.dev/kotlin-dependency-injection-with-the-reader-monad