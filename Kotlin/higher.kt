interface IS<T> { fun T.f(): T}
class IntIS(): IS<Int> {
     override fun Int.f(): Int {
        return this+1
    }
}

class StringIS(): IS<String> {
    override fun String.f(): String{
        return this.reversed()
    }
}
fun <T> g(x: T):Any? {
    if (x is Int) {
        with(IntIS()){
            return x.f()
        }
    }
    else if (x is String) {
        with(StringIS()){
            return x.f()
        }
    }
    else return x
}
fun <T> g2(x: T):Any? {
    if (x is Int) return x+1
    else if (x is String) return x.reversed()
    else return x
}

interface NIS<T> {fun T.fmap():T}
sealed class NIIS<T>: NIS<T>
data class NIntIS(val x: Int): NIIS<Int>(){
   override fun Int.fmap(): Int{
       return this+x+1
   }
}

data class NStringIS(val x: String): NIIS<String>(){
    override fun String.fmap(): String{
        return (this+x).reversed()
    }
}
fun <T>g3(x: NIIS<T>):Any{
    if (x is NIntIS){
       with(NIntIS(0)) {
           return NIntIS(x.x.fmap())
       }
    }
    if (x is NStringIS){
        with(NStringIS("")){
            return NStringIS(x.x.fmap())
        }
    }
    return x
}


fun main(){
    println(g(2))
    println(g("123"))
    println(g2(3))
    println(g2("2323"))
    println(g3(NIntIS(3)))
    val gg =g3(NStringIS("321"))




}

