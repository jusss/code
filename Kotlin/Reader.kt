ReaderT Config (EitherT Error IO) ()
ReaderT Config -> EitherT Error IO ()  is a type notation, has above type

EitherT Error IO is m here, because IO need IO ()
EitherT Error IO () is whole

Reader r a, r is input type, a is result type 

r = ReaderT Config -> EitherT Error IO ()
runReaderT r Config -- this return EitherT IO (Either Error ())

------------------------------------
newtype ReaderT r m a = ReaderT { runReaderT :: r -> m a }

ask :: ReaderT r m r
<- ask will get r from ReaderT r m a

f :: a -> a
f = do
    x <- (+1)
    y <- (+2)
    return (x+y)

f :: Reader a a
f = do
    x <- return (+1)
    y <- return (+2)
    return (x+y)

here, m ~ ((->) a)

same thing as Reader but without newtype wrappers

Reader's benefits just same as functions, but it's even less convenient than functions
in most cases
ReaderT doesn't solve any problem, it's just style and convenience


f :: Reader a a
f = do
    x <- return (+1) -- return (+1) fit Reader a a, and it works on parameter
    y <- return (+2) -- return (+1) fit Reader a a, and it works on parameter, not x
    return (x+y)

every line in do notation, it works on one same parameter,
unless it declares to use previous results

it's 
return a >>= \a -> return $ (+1) a
        >>= \x -> return $ (+2) a
        >>= \y -> return (x+y)

    
