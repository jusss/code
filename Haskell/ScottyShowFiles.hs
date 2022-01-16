{-# LANGUAGE OverloadedStrings #-}
import Network.Wai
import Network.HTTP.Types
import Network.Wai.Handler.Warp (run)
import Web.Scotty
import Control.Monad.IO.Class
import System.Directory
import Control.Monad
import System.Environment

--main = do
 --   fileList <- getDirectoryContents "/tmp"
  --  traverse print fileList


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

main = do
    fileList <- getDirectoryContents "docs"
    traverse print fileList
    writeFile "index.html" " "
    appendFile "index.html" "<html>\n" 
    appendFile "index.html" "<head>\n" 
    appendFile "index.html" "<title>welcome</title>\n" 
    appendFile "index.html" "</head>\n" 
    appendFile "index.html" "<body>\n" 
    traverse (\x -> appendFile "index.html" $ "<a href=\"docs/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList
    appendFile "index.html" "</body>\n" 
    appendFile "index.html" "</html>\n" 
    -- <a href="path"> name </a>
    scotty 8080 $ do
    get "/" $ file "index.html"

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
