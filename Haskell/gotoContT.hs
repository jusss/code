{-# LANGUAGE ScopedTypeVariables #-}

import qualified Control.Monad.Trans.Cont  as C
import           Control.Monad.Trans.Class (lift)
import           System.Random             as R

--simple goto
goto = C.callCC $ \out -> let fn = out fn
                          in return fn

-- we can also provide back other arguments, in this
-- case some number, to allow more intelligent looping:
gotoC = C.callCC $ \out -> let fn num = out (fn, num)
                           in return (fn, 0)
-- based on the output of a random number generator,
-- we either go back to marker1, marker2, or finish
gotoEx1 = flip C.runContT return $ do

    marker1 <- goto
    lift $ putStrLn "one"

    marker2 <- goto
    lift $ putStrLn "two"

    (num :: Int) <- lift $ R.randomRIO (0,2)

    if num < 1 then marker1
    else if num < 2 then marker2
    else lift $ putStrLn "done"

-- loop back some number of times before continuing on:
gotoEx2 = flip C.runContT return $ do

    (marker1,num) <- gotoC
    lift $ putStrLn ("count: "++show num)

    if num < 10 then marker1 (num+1)
    else lift $ putStrLn "done"

main = gotoEx1
