package poly

sealed class E
data class L(val v: String) : E()
data class R(val v: Int): E()


fun poly(expr: E):E  = when(expr) {
    is L -> L(expr.v)
    is R -> R(expr.v + 1)
}
fun poly2(expr: E):Any?  = when(expr) {
    is L -> expr.v
    is R -> expr.v + 1
}
fun main(){
    val t = poly(L("aha"))
    println(poly(poly(R(3))))
    println(poly2(R(9)))
    println(L("a").v)
}
