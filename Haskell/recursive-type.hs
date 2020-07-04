newtype Consumer a = C (a -> IO (Consumer a))
runConsumer :: Consumer a -> a -> IO (Consumer a)
runConsumer (C f) x = f x
f :: Show a => Consumer a; 
f = C (\x -> do print x; return f)

-- main = do 
--     f' <- runConsumer f 3; 
--     f'' <- runConsumer f' 4; 
--     f''' <- runConsumer f'' 5; 
--     return f'''
-- 
main = do
    f <- runConsumer f 3
    f <- runConsumer f 4
    f <- runConsumer f 5
    return f
