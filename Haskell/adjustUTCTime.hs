import Data.Time.Clock
main = do
    t <- getCurrentTime
    {- add 8 hours from UTC 0 to get UTC +8 -}
    print $ addUTCTime (60*60*8 :: NominalDiffTime) t
