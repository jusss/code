{-# LANGUAGE OverloadedStrings #-}
import Network.Wai
import Network.HTTP.Types
import Network.Wai.Handler.Warp (run)
import Web.Scotty

app :: Application
app _ respond = do
    putStrLn "I've done some IO here"
    respond $ responseLBS
        status200
        [("Content-Type", "text/plain")]
        "Hello, Web!"

main :: IO ()
--main = do
    --putStrLn $ "http://localhost:8080/"
    --run 8080 app
    
main = scotty 8080 $ do
    get "/test.mp3" $ file "./test.mp3"
