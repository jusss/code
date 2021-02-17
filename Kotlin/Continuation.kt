is there Cont Monad in arrow-kt?
suspend () -> A is treated as the continuation and IO monad since through the continuation callback we can go to other typed values. We have reset / shift as primitives on arrow-continuations to build effect handlers on top suspension. @Ifvwm is there a particular use case that you are looking into supporting?
callCC implement? @raulraja

Not exactly callCC , we have an effect interface which exposes the Delimited scope via reset/shift and starts the continuation in suspended (letting effects passthrough through the use) and restricted (Restricts suspension points) . Here is an example where we implement monad bind with continuations over Either using shift. Unlike in abstract implementations these binds can be specialised in this case to fold because they are suspended. https://github.com/arrow-kt/arrow-core/blob/b67de8fc0a24b96779ce3afb323f00767b1835[…]row-core-data/src/main/kotlin/arrow/core/computations/either.kt (edited) 
GitHubGitHub
arrow-kt/arrow-core
Λrrow Core is part of Λrrow, a functional companion to Kotlin's Standard Library - arrow-kt/arrow-core

Raul Raja [Λrrow]:arrow:  5 days ago
The effect interface and other internals like reset/shift are in arrow-continuations

Ifvwm  4 days ago
class Cont<R,A>(f : ((A)->R)->R){
  fun runCont(g: (A)->R): R{
    return f(g)
  }
}

fun <A,R,B> callCC(f: ((A)-> Cont<R,B>)-> Cont<R,A>): Cont<R,A> = {g: (A)-> Cont<R,B> -> f(g)}

Ifvwm  4 days ago
is this properly?