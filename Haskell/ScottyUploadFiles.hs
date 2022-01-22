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
import qualified System.Posix.IO as SPI
import qualified Data.List as DL
import qualified Data.Text as DT
import qualified Data.Text.IO as DTI
import qualified Data.Text.Lazy as DTL
import qualified Data.ByteString as D
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

insertFile :: FilePath -> String -> IO ()
insertFile filePath str = do
    content <- D.readFile filePath
    D.writeFile filePath $ (BSC.pack str) <> content

generatePasteHtml :: String -> IO ()
generatePasteHtml pathName = do
        let fileName = pathName <> ".html"
        writeFile fileName $ "<html lang=\"en-US\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">  <title>" <> pathName <> "</title>\n </head>\n <body>\n"
        appendFile fileName $ "<form enctype=\"multipart/form-data\" action=\"/" <> pathName <> "\" method=\"post\">"
        appendFile fileName $ "<input type=\"text\" name=\"" <> pathName <> "\" multiple> <input type=\"submit\" value=\"Submit\"> </form> <br>"
        appendFile (pathName <> ".txt") "\n"
        content <- fmap lines $ readFile $ pathName <> ".txt"
        --let _content = foldl1 <> (fmap (\x -> x <> "<br>") $ DT.splitOn '\n' content)
        appendFile fileName $ join $ fmap (\x -> x <> "<br>") content
        appendFile fileName "</body>\n </html>\n" 

generateIndexHtml :: String -> IO ()
generateIndexHtml pathName = do
        --_fileList <- getDirectoryContents pathName
        _fileList <- listDirectory pathName
        --let fileList = DL.sort _fileList
        --let fileList = [".", ".."] <> (filter (== "..") $ filter (== ".") _fileList)
        let fileList = [".", ".."] <> _fileList
        let fileName = pathName <> ".html"
        writeFile fileName " "
        appendFile fileName $ "<html lang=\"en-US\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> <title>" <> pathName <> "</title>\n </head>\n <body>\n"
        appendFile fileName $ "<form enctype=\"multipart/form-data\" action=\"/" <> pathName <> "\" method=\"post\">"
        appendFile fileName $ "<input type=\"file\" name=\"" <> pathName <> "\" multiple> <input type=\"submit\" value=\"Submit\"> </form> <br>"
        -- <a href="path"> name </a>
        appendFile fileName $ foldl1 (<>) (fmap (\x -> "<a href=\"" <> pathName <> "/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList)
        -- traverse (\x -> liftIO $ appendFile "uploadFile.html" $ "<a href=\"uploadFile/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList
        appendFile fileName "</body>\n </html>\n" 

postAndShow :: String -> ScottyM ()
postAndShow pathName =
    post (capture pathName) $ do
        _files <- files
        traverse (\_file -> liftIO $ DB.writeFile ((DTL.unpack $ fst _file) <> "/" <> (BSC.unpack $ fileName $ snd _file)) (fileContent $ snd _file)) _files
        traverse (\_file -> liftIO $ generateIndexHtml (DTL.unpack $ fst _file)) _files
        liftIO $ print $ pathName <> " upload done"
        file $ (drop 1 pathName) <> ".html"

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

    writeFile "index.html" " "
    appendFile "index.html" $ "<html lang=\"en-US\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> <title> index </title>\n </head>\n <body>\n"
    appendFile "index.html" $ foldl1 (<>) (fmap (\x -> "<a href=\"" <> x  <> "\"> " <> x <> "</a> <br> <br> <br>" <> "\n") ["/paste", "/docs", "/config", "/code", "/upload", "/text", "/audio", "/video", "/picture", "/others"])
    appendFile "index.html" "</body>\n </html>\n" 

    generatePasteHtml "paste"

    scotty 8080 $ do
    --get "/" $ text "docs, config, code, upload, text, audio, video, picture, others"
    get "/" $ file "index.html"
    get "/docs" $ file "docs.html"
    get "/code" $ file "code.html"
    get "/config" $ file "config.html"
    get "/upload" $ file "upload.html"
    get "/text" $ file "text.html"
    get "/audio" $ file "audio.html"
    get "/video" $ file "video.html"
    get "/picture" $ file "picture.html"
    get "/others" $ file "others.html"
    get "/paste" $ file "paste.html"

    --post "/upload" $ do
        --_files <- files
        --traverse (\_file -> liftIO $ DB.writeFile ((DTL.unpack $ fst _file) <> "/" <> (BSC.unpack $ fileName $ snd _file)) (fileContent $ snd _file)) _files
        --traverse (\_file -> liftIO $ generateIndexHtml (DTL.unpack $ fst _file)) _files
        --liftIO $ print "upload done"
        --file "upload.html"

    postAndShow "/upload"
    postAndShow "/text"
    postAndShow "/picture"
    postAndShow "/audio"
    postAndShow "/video"
    postAndShow "/others"

    post "/paste" $ do
    -- submit form data is post with params
        _params <- params
        --traverse (\_param -> liftIO $ appendFile ((DTL.unpack $ fst _param) <> ".txt") (DTL.unpack $ (snd _param) <> "\n")) _params
        traverse (\_param -> liftIO $ insertFile ((DTL.unpack $ fst _param) <> ".txt") (DTL.unpack $ (snd _param) <> "\n")) _params
        liftIO $ generatePasteHtml "paste"
        file "paste.html"

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
