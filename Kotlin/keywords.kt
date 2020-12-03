use is sugar for try-with-resources
by is for delegates, a by b, getValue or setValue on a, is on b
as is for casts, a.toString() could be a as String, cast a to String object
is , objA is ClassA, check objA is an instance of ClassA or not

with, call methods with one object
with(objA) { m1(); m2() ... } // will call objA.m1(); objA.m2()...

apply, set attributes with one object
val objA = ClassA().apply { a = 1; b = 2; } // will do objA.a = 1; objA.b =2

try, like python's with...as, auto close resource
Files.newInputStream(Paths.get("file.txt")).buffered().reader().use { println (it.readText()) } // it doesn't need to close the file resource

val list = listOf("a","b","c")
val map = mapOf("a" to 1, "b" to 2)

create singleton
object A {
       init { ... }
}

https://www.kotlincn.net/docs/reference/idioms.html
