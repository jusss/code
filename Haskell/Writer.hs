import Control.Monad.Writer
import Data.Time

-- :info! WriterT to get WriterT's definition
-- :t writer (3, "3") :: Writer String Int 
-- that'll let you test such hypotheses

-- data Writer w a = Writer { runWriter :: (a, w) }
-- newtype WriterT w m a = WriterT { runWriterT :: m (a, w) }
-- type Writer w = WriterT w Identity

half :: Int -> Writer String Int
half x = do
     tell ("halved " <> (show x) <> ",")
     return (x `div` 2)  -- context is Writer ( ,String)

-- main = print $ runWriter (half 16 >>= half >>= half)  

--main = print $ runWriter $ writer (16, "16 ")

-- Writer isn't an instance of MonadIO, so liftIO can't lift IO into it
-- WriterT is an instance of MonadIO, which liftIO can lift IO into
halfWriter :: WriterT String IO Int -> WriterT String IO Int
halfWriter x = do
    v2 <- (liftIO getCurrentTime)
    v <- x
    tell ((show v) <> "," <> (show v2) <> ",")
    return (v `div` 2)

main = do
    l <- runWriterT $ halfWriter (writer (16, ""):: WriterT String IO Int)
    l2 <- runWriterT $ halfWriter (writer l :: WriterT String IO Int)
    print l2

-- main = print =<< (runWriterT $ halfWriter (writer (16, ""):: WriterT String IO Int))
    

-- == (2,"halved 8,halved 4,")

--main = print $ runWriter ( writer ("3", 3 :: Sum Int))
--main = print $ runWriter ( writer ("3", Just "3"))
