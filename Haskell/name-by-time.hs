import Data.Time.Clock.POSIX
main = do 
    now <- getPOSIXTime
    let fileName = (take 10 $ show now) ++ ".txt"
    let content = "hello"
    writeFile fileName content
