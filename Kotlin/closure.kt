fun counter():()->Int{
    var c=0
    fun g():Int{
        c++
        return c
    }
    return ::g //'cause return g will return variable g, return::g mean return function g
}

val c = counter()
println(c())
println(c())

or 
fun counter():()->Int{
    var c=0
    val g:()->Int = {
        c++
        c
    }
    return g
}

you can contain the type with `()', val g:(()->Int) = { c++; c}
    val c1:()->()->Int = {
        var c=0
        val g= {
            c++
            c
        }
        g
    }

val counter:()->()->Int = { var c=0; {c++; c}}

::g mean g is a callable reference
::isOdd, String::toInt, List<Int>::size

val stringPlus: (String,String)->String = String::plus
stringPlus("Hello, ", "world!")

val intPlus: Int.(Int) -> Int = Int::plus
intPlus(1,2)
