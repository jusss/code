import Data.Time
import Data.Time.Clock.POSIX
import Data.Int
import Data.Maybe
import Control.Monad.Reader
import Control.Monad.Writer
import Control.Monad.State

-- module X where

-- se :: UTCTime -> Int64
-- se = floor . (le9 *) . nominalDiffTimeToSeconds . utcTimeToPOSIXSeconds



-- data Writer w a = Writer { runWriter :: (a, w) }
half :: Int -> Writer String Int
half x = do
     tell ("halved " <> (show x) <> ",")
     return (x `div` 2)

greeter :: Reader String String
greeter = do
        name <- ask
        return ("hello, " <> name <> ",")

-- main = print $ runWriter (half 8 >>= half)

greeter2 :: State String String
greeter2 = do
        name <- get
        put "tintin"
        return ("hello, " <> name <> ",")

main = print $ runState greeter2 "Joe"
