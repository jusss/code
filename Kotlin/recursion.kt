     fun z3(x:Int):Int {
        if (x > 0) return x
        else return z3(x + 1)
    }

'cause kotlin doesn't allow recursive call in lambda, so do it in functions
