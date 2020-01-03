import Control.Monad.Cont

foo :: Int -> Cont r String
foo x = callCC $ \k -> do
    let y = x ^ 2 + 3
    when (y > 20) $ k "over twenty"
    return (show $ y - 4)


bar :: Char -> String -> Cont r Int
bar c s = do
    msg <- callCC $ \k -> do
        let s0 = c : s
        when (s0 == "hello") $ k "They say hello."
        let s1 = show s0
        return ("They appear to be saying " ++ s1)
    return (length msg)

-- callCCex1 = callCC $ \exit -> do
--        exit True
--        undefined



kn :: Bool -> String
kn True = "it's true"
kn False = "it's false"

-- main = print $ runCont callCCex1 kn

ex2 = callCC $ \cc -> do

    cc True


-- main = print $ runCont (callCC $ \cc -> cc True) kn
main = print $ runCont ex2 kn
