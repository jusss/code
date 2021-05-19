fun main(){
    val alist = arrayListOf<String>("eat","chicken","lunch")
    val astr = "I would like to eat chicken and banana for lunch"
    println(matchStringByOrder(alist,astr))
}

//  check if the string contain all the elements, then check if the index of elements in the string sequenced by order
fun matchStringByOrder(alist: ArrayList<String>, astr: String) : Boolean {
    // check if contain all
    val containAll: ArrayList<Boolean> = arrayListOf()
    alist.map {
        if (astr.contains(it)) containAll.add(true) else containAll.add(false)
    }

    // get index , -1 mean not found, then check index order
    val indexPosition: ArrayList<Int> = arrayListOf()
    alist.map {
        indexPosition.add(astr.indexOf(it))
    }

    return when {
        containAll.contains(false) -> false
        indexPosition.contains(-1) -> false
        isSorted(indexPosition) -> true
        else -> false
    }
}

fun isSorted(a: List<Int>): Boolean {
    for (i in 0 until a.size - 1)
    {
        if (a[i] > a[i + 1]) {
            return false
        }
    }
    return true
}

