fun main(){

    val reverse2 = {i: String -> i.reversed()}

    //1. function take function as parameter, function need to be defined with lambda expression?
    // fun reverse2(val x: String): String = x.reversed() is not take by fmap(f: (String) -> String)
    // 2. ArrayList is a functor, DownloadStructure could be a Functor, so visit a in ArrayList<DownloadStructure>
    // need fmap . fmap, so make ArrayList<DownloadStruture> a MonadTransformer, fmap = fmap . fmap
    // Sum type just work on one type, like Functor Set (a,b) work on b
    // if you want to make a Sum Type as a Functor, you just need to let fmap f work on one of its sub type,
    // like fmap f (a,b) = (a, f b)
    // 3. t = [Just 3, Just 2] , if you want (+1) work on 3 or 2, you may use (fmap . fmap) (+1) t
    // but also you can turn it to MaybeT [] a = MaybeT [] (Maybe a)
    // fmap (+1) $ MaybeT [Just 3, Just 2]
    // (fmap . fmap) (+1) [[1],[2,3]]  could use fmap (+1) $ Compose [[1],[2,3]]

    val t1 = arrayListOf<DownloadStructure>()
    t1.add(DownloadStructure("file1", "web1", 30))
    t1.add(DownloadStructure("file2", "web2", 30))
    t1.add(DownloadStructure("file2", "web3", 30))

    val t2 = DownloadStructureT(t1).fmap(reverse2)
    println(t2.a)
}

data class DownloadStructure(var name: String, var link: String, var size: Int)

// this make DownloadStructure String   Int as a Functor to DownloadStructure String a Int, so all next operations no need point it.link
fun DownloadStructure.fmap(f: (String) -> String): DownloadStructure{
    this.link = f(this.link)
    return this
}

class DownloadStructureT(val a: ArrayList<DownloadStructure>) {
    fun fmap(f: (String) -> String): DownloadStructureT {
        a.map {
            it.link = f(it.link)
        }
        return DownloadStructureT(a)
    }
}

after DownloadStructure String Int as a Functor, so it could be 

class DownloadStructureT(val a: ArrayList<DownloadStructure>) {
    fun fmap(f: (String) -> String): DownloadStructureT {
        a.map {
            // it.link = f(it.link)
            it.fmap(f)
        }
        return DownloadStructureT(a)
    }
}
