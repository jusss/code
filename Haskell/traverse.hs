import Data.Traversable
import Control.Monad.Trans.Maybe

-- since IO isn't a data constructor, use `return` to create a value has IO type
-- MaybeT (return Nothing) :: MaybeT IO Int
-- return 3 :: MaybeT IO Int
-- mzero :: MaybeT IO Int


-- just look its type!
-- traverse :: (Traversable t, Applicative f) => (a -> f b) -> t a -> f (t b)
-- when MaybeT IO ~ t, Maybe ~ f
-- traverse :: (Traversable t, Applicative f) => (a -> [b]) -> MaybeT IO a -> f (t b)



--f :: a -> Either String a
--f x = if (x == 3) then Right 3 else Left "not 3"

-- fetchUrl :: Int -> MaybeT IO Int
-- fetchUrl x = if (x == 0) then MaybeT (return Nothing) else return x
fetchUrl :: Int -> MaybeT IO Int
fetchUrl x = MaybeT $ do
    if (x == 3) then (return Nothing) else (return (Just x))
    

l = traverse fetchUrl [3,2,0] -- MaybeT IO (Maybe [Int])

main = runMaybeT l >>= print
