{-# LANGUAGE OverloadedStrings #-}
import Network.Wai
import Network.HTTP.Types
import Network.Wai.Handler.Warp (run)
import Web.Scotty
import Control.Monad.IO.Class
import System.Directory
import Control.Monad
import System.Environment
import Network.Wai.Parse
import qualified Data.Text as T
import qualified Data.Text.Lazy as DTL
import qualified Data.ByteString.Lazy as DB
import qualified Data.ByteString.Lazy.UTF8 as DBLU
import qualified Data.ByteString.Char8 as BSC

-- create 'docs', 'config', 'code', 'text', 'audio', 'picture', 'video', 'others' 
-- put this file and upload.html on the same path with that
-- runghc ScottyUploadFiles.hs

--main = do
 --   fileList <- getDirectoryContents "/tmp"
  --  traverse print fileList

--main = do
    --putStrLn $ "http://localhost:30080/"
    --run 30080 app

app :: Application
app _ respond = do
    putStrLn "I've done some IO here"
    respond $ responseLBS
        status200
        [("Content-Type", "text/plain")]
        "Hello, Web!"

generateIndexHtml :: String -> IO ()
generateIndexHtml pathName = do
        fileList <- getDirectoryContents pathName
        let fileName = pathName <> ".html"
        writeFile fileName " "
        appendFile fileName $ "<html>\n <head>\n <title>" <> pathName <> "</title>\n </head>\n <body>\n"
        -- <a href="path"> name </a>
        appendFile fileName $ foldl1 (<>) (fmap (\x -> "<a href=\"" <> pathName <> "/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList)
        -- traverse (\x -> liftIO $ appendFile "uploadFile.html" $ "<a href=\"uploadFile/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList
        appendFile fileName "</body>\n </html>\n" 

main :: IO ()
main = do
    traverse generateIndexHtml ["docs", "code", "config", "text", "audio", "video", "picture", "others"]
    --fileList <- getDirectoryContents "docs"
    --traverse print fileList
    --writeFile "docs.html" " "
    --appendFile "docs.html" "<html>\n" 
    --appendFile "docs.html" "<head>\n" 
    --appendFile "docs.html" "<title>welcome</title>\n" 
    --appendFile "docs.html" "</head>\n" 
    --appendFile "docs.html" "<body>\n" 
    --traverse (\x -> appendFile "docs.html" $ "<a href=\"docs/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList
    --appendFile "docs.html" "</body>\n" 
    --appendFile "docs.html" "</html>\n" 
    -- <a href="path"> name </a>

    scotty 8080 $ do
    get "/" $ text "docs, config, code, upload, text, audio, video, picture, others"
    get "/docs" $ file "docs.html"
    get "/code" $ file "code.html"
    get "/config" $ file "config.html"
    get "/upload" $ file "upload.html"
    get "/text" $ file "text.html"
    get "/audio" $ file "audio.html"
    get "/video" $ file "video.html"
    get "/picture" $ file "picture.html"
    get "/others" $ file "others.html"

    post "/upload" $ do
        _files <- files
        traverse (\_file -> liftIO $ DB.writeFile ((DTL.unpack $ fst _file) <> "/" <> (BSC.unpack $ fileName $ snd _file)) (fileContent $ snd _file)) _files
        traverse (\_file -> liftIO $ generateIndexHtml (DTL.unpack $ fst _file)) _files
        liftIO $ print "upload done"

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
