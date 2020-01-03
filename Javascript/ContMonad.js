// m a ~ (a->r)->r
// pure :: a -> m a
const pure = x => cb => cb(x)

// bind :: m a -> (a -> m b) -> m b
const bind = ma => amb => cb => ma(a => amb(a)(cb))

// delay(1000)("hello") :: m a
const delay = d => v => cb => setTimeout(() => cb(v), d)

// callcc :: ((a->m b) -> m a) -> m a
// f :: ((a->m b)->m a)
// cc :: (a->r)
// callcc f :: m a
// m ~ (a->r)->r
// callcc f cc :: r
const callcc = f => cc => f( x => _ => cc(x))(cc)

// f :: (a-> m b) -> m a
// f :: (a -> (b -> r) -> r) -> (a->r)->r
// k ::  a -> (() -> r) -> r
// _ :: () -> r
const f = k => _ => k(3)(_)
// f is for callcc, callcc f :: m a
// k is the escape function, k's first parameter is the result of f

const cont = bind(callcc(f))( a => pure(a+2))
// cont(console.log) == 5
// bind(cont)( a => pure(a+3))(console.log) == 8

const gf = x => k => _ => k(x)(_)
// gf is short for generate function f for callcc, like pure for >>=
// callcc $ gf a :: m a

const cont2 = bind(callcc(gf("hello")))( a => delay(1000)( a + ", world"))
// cont2(console.log) == hello, world
// callcc(f)(console.log) == 3

const format = x => y => `${x}, ${y}!`
const hello = delay(1000)("hello")
const world = delay(1000)("world")

// liftA2 is another version of fmap
// liftA2 :: (a->b->c) -> f a -> f b -> f c
const liftA2 = f => ma => mb => bind(ma)(a => bind(mb)(b => pure(f(a)(b))))
// liftA2(format)(hello)(world)(console.log) == hello, world

// fmap :: (a->b) -> f a -> f b
const fmap = f => ma => bind(ma)( a => pure(f(a)))
// fmap( x => x + ", world")(hello)(console.log) == hello, world
// fmap( x => "replace")(hello)(console.log) == replace

