and lazy is used to val, lateinit is used to var

lazy will only eval once, if null then init else return
val x: String by lazy { println("evaluated"); "hello" }
print(x) because x is null at first so it will output "evaluated" "hello"
then x will have "hello" as value
call print(x) again, it will only output "hello"

it's like run a sequence actions and use last action's result as its value
and only run them once