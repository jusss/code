{-# LANGUAGE OverloadedStrings #-}
import Network.Wai
import Network.HTTP.Types
import Network.Wai.Handler.Warp (run)
import Web.Scotty
import Control.Monad.IO.Class

-- git clone blockly, then copy this file and index.html into that blockly 
-- cd into it
-- run `runghc scotty.blockly.hs`

app :: Application
app _ respond = do
    putStrLn "I've done some IO here"
    respond $ responseLBS
        status200
        [("Content-Type", "text/plain")]
        "Hello, Web!"

main :: IO ()
--main = do
    --putStrLn $ "http://localhost:30080/"
    --run 30080 app

main = scotty 30080 $ do
    get "/" $ file "demos/fixed/index.html"

    get "/:file" $ do
         _file <- param "file"
         liftIO $ putStrLn _file
         file _file

    get "/:to/:file" $ do
        _to <- param "to"
        _file <- param "file"
        let dest = _to <> "/" <> _file
        liftIO $ putStrLn dest
        file $ dest

    get "/:path/:to/:file" $ do
        _path <- param "path"
        _to <- param "to"
        _file <- param "file"
        let dest = _path <> "/" <> _to <> "/" <> _file
        liftIO $ putStrLn dest
        file $ dest

--     get "/blockly_compressed.js" $ file "blockly_compressed.js"
--     get "/blocks_compressed.js" $ file "blocks_compressed.js"
--     get "/msg/js/en.js" $ file "msg/js/en.js"
--     get "/msg/js/:word" $ do
--          w <- param "word"
--          liftIO $ print w
--          file $ "msg/js/" <> w
