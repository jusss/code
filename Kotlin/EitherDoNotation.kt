    suspend fun test() =
    either<String, Int> {
        val (a) = t2
        val (b) = Either.Right(1 + a)
        val (c) = Either.Right(1 + b)
        a + b + c
    }

https://arrow-kt.io/docs/apidocs/arrow-core-data/arrow.core/-either/index.html#either

The one that will be preserved in 0.12 and forward looks like this:
either {
  val r1 = eitherValueOfInt.bind()
  val r2 = eitherValue2OfInt.bind()
  r1 + r2
}