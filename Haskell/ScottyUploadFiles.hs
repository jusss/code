{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
import Network.Wai
import Network.HTTP.Types
import Network.Wai.Handler.Warp (run)
import Web.Scotty
import Web.Scotty.Login.Session
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

-- git clone https://github.com/asg0451/scotty-login-session.git
-- cd scotty-login-session
-- cabal v2-build
-- cabal v2-install --lib
-- create 'docs', 'config', 'code', 'text', 'audio', 'picture', 'video', 'others' 
-- put this file and upload.html on the same path with that
-- ghc ScottyUploadFiles.hs -optl-static -package scotty -package wai-extra -package wai -package http-types -package warp -package utf8-string
-- ./ScottyUploadFiles

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

conf :: SessionConfig
conf = defaultSessionConfig

insertFile :: FilePath -> String -> IO ()
insertFile filePath str = do
    content <- D.readFile filePath
    D.writeFile filePath $ (BSC.pack str) <> content

insertFileWithByteString :: FilePath -> D.ByteString -> IO ()
insertFileWithByteString filePath byteString = do 
    content <- D.readFile filePath 
    D.writeFile filePath $ byteString <> content

generatePasteHtml :: String -> IO ()
generatePasteHtml pathName = do
        let fileName = pathName <> ".html"
        writeFile fileName $ "<html lang=\"zh-CN\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">  <title>" <> pathName <> "</title>\n </head>\n <body>\n"
        appendFile fileName $ "<form enctype=\"multipart/form-data\" action=\"/" <> pathName <> "\" method=\"post\">"
        appendFile fileName $ "<textarea rows=\"6\" cols=\"56\" name=\"" <> pathName <> "\"></textarea>  <input type=\"submit\" value=\"Submit\"> </form> <br>"
        {-D.appendFile (pathName <> ".txt") $ BSC.pack "\n"-}
        {-content <- fmap BSC.unpack $ fmap BSC.lines $ D.readFile $ pathName <> ".txt"-}
        byteData <- D.readFile $ pathName <> ".txt"
        {-let content = fmap BSC.unpack $ BSC.lines byteData-}
        --let _content = foldl1 <> (fmap (\x -> x <> "<br>") $ DT.splitOn '\n' content)
        {-appendFile fileName $ join $ fmap (\x -> x <> "<br>") content-}
        {-appendFile fileName $ BSC.unpack byteData-}
        D.appendFile fileName byteData
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
    post (capture pathName) $ authCheck (redirect "/denied") $ do
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
    
    D.appendFile "paste.txt" $ BSC.pack "\n<br>"

    generatePasteHtml "paste"

    initializeCookieDb conf

    scotty 8080 $ do
    --get "/" $ text "docs, config, code, upload, text, audio, video, picture, others"
    get "/" $ authCheck (redirect "/login") $ file "index.html"
    get "/docs" $ authCheck (redirect "/denied") $ file "docs.html"
    get "/code" $ authCheck (redirect "/denied") $ file "code.html"
    get "/config" $ authCheck (redirect "/denied") $ file "config.html"
    get "/upload" $ authCheck (redirect "/denied") $ file "upload.html"
    get "/text" $ authCheck (redirect "/denied") $ file "text.html"
    get "/audio" $ authCheck (redirect "/denied") $ file "audio.html"
    get "/video" $ authCheck (redirect "/denied") $ file "video.html"
    get "/picture" $ authCheck (redirect "/denied") $ file "picture.html"
    get "/others" $ authCheck (redirect "/denied") $ file "others.html"
    get "/paste" $ authCheck (redirect "/denied") $ file "paste.html"
    get "/denied" $ text "access denied"
    get "/login" $ do html $ DTL.pack $ unlines $
                        [ "<form method=\"POST\" action=\"/login\">"
                        , "<input type=\"text\" placeholder=\"user\" name=\"username\">"
                        , "<input type=\"password\" placeholder=\"password\" name=\"password\">"
                        , "<input type=\"submit\" name=\"login\" value=\"login\">"
                        , "</form>" ]
    post "/login" $ do
        (usn :: String) <- param "username"
        (pass :: String) <- param "password"
        if usn == "user" && pass == "password"
            then do addSession conf
                    redirect "/"
            else do redirect "/denied"

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

    post "/paste" $ authCheck (redirect "/denied") $ do
    -- submit form data is post with params
        {-_params <- params-}
        --traverse (\_param -> liftIO $ appendFile ((DTL.unpack $ fst _param) <> ".txt") (DTL.unpack $ (snd _param) <> "\n")) _params
        {-traverse (\_param -> liftIO $ insertFile ((DTL.unpack $ fst _param) <> ".txt") (DTL.unpack $ (snd _param) <> "\n")) _params-}
        binaryData <- param "paste"
        let binaryDataList = BSC.lines binaryData
        liftIO $ insertFileWithByteString "paste.txt" $ BSC.concat $ fmap (<> (BSC.pack "<br>")) binaryDataList
        {-liftIO $ D.appendFile "paste.txt" binaryData -}
        {-liftIO $ insertFileWithByteString "paste.txt" $ BSC.pack "\n<br>"-}
        {-liftIO $ insertFileWithByteString "paste.txt" binaryData-}
        {-byteData <- liftIO $ D.readFile "paste.txt"-}
        {-text $ DTL.pack $ BSC.unpack byteData-}
        liftIO $ generatePasteHtml "paste"
        file "paste.html"

    get "/:file" $ authCheck (redirect "/denied") $ do
         _file <- param "file"
         liftIO $ putStrLn _file
         file _file

    get "/:to/:file" $ authCheck (redirect "/denied") $ do
        _to <- param "to"
        _file <- param "file"
        let dest = _to <> "/" <> _file
        liftIO $ putStrLn dest
        file $ dest

    get "/:path/:to/:file" $ authCheck (redirect "/denied") $ do
        _path <- param "path"
        _to <- param "to"
        _file <- param "file"
        let dest = _path <> "/" <> _to <> "/" <> _file
        liftIO $ putStrLn dest
        file $ dest
