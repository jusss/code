import Control.Monad.Cont

-- retun x = cont (\_ -> _ x)
-- return 1 = cont (\k -> k 1)
-- a <- return 1   a is 1

ex2 = do
    a <- cont (\x -> x 1)
    --    b <- cont (\k -> k 10 ++ k 20)
    --    b <- cont (\k -> concat [k 10, k 20])
    b <- cont (\k -> [10, 20] >>= k)
    -- b <- cont [10,20]
    return $ a+b

-- test2 = runCont ex2 show
test2 = runCont ex2 return

-- i is k, i is call/cc
i x = cont (\fred -> x >>= fred)

run m = runCont m return

test9 = run $ do
    a <- i [1, 2]
    b <- i [10,20]
    return $ a+b

--main = print test9



--    main = print test2
-- https://www.schoolofhaskell.com/school/to-infinity-and-beyond/pick-of-the-week/the-mother-of-all-monads

boom2C = do
    n <- cont $ \out -> out "1" ++ out "2"
    l <- cont $ \out -> "boom! "
    x <- cont $ \out -> out "X" ++ out "Y"
    return $ n++l++x++" "

main = print $ runCont boom2C id
