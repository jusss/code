
//伴生对象无法访问类的属性，但是可以类初始化时访问伴生对象的属性

//python类变量, Java public static变量, Kotlin伴生对象
//如果伴生对象有名字就用 ClassName.CompanionName.attr去访问
//没有名字就直接ClassName.attr去访问

class A (val x: String) {
    companion object instance {
        lateinit var y: String
    }
    init {
        A.instance.y = x
    }
}

fun main() {
    val objA = A("hello")
    println(A.instance.y)
} // will output "hello"


class A (val x: String) {
    companion object {
        lateinit var y: String
    }
    init {
        A.y = x
    }
}

fun main() {
    val objA = A("hello")
    println(A.y)
} // will output "hello"

