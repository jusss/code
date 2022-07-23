{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
import Network.Wai
import Network.Wai.Parse
import Network.HTTP.Types
import Network.Wai.Handler.Warp (run)
import Web.Scotty
import Web.Scotty.Login.Session
import Web.Scotty.Cookie
import Control.Monad.IO.Class
import Control.Monad
import System.Environment
import System.Directory
import System.IO
import Data.Maybe
import Data.Binary.Builder
import Data.Text.Lazy.Encoding
{- import GHC.Num.Integer -}
import qualified System.Posix.IO as SPI
import qualified Data.List as DL
import qualified Data.Text as DT
import qualified Data.Text.IO as DTI
import qualified Data.Text.Lazy as DTL
import qualified Data.ByteString as D
import qualified Data.ByteString.Lazy as DB
import qualified Data.ByteString.Lazy.UTF8 as DBLU
import qualified Data.ByteString.Char8 as BSC
import Network.Wai.Middleware.Gzip (gzip, def, gzipFiles, GzipFiles(GzipCompress))

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

{-getFile restrictList =-}
    {-flip traverse restrictList $ \x ->-}
    {-get (x <> "/:file") $ do-}
        {-_file <- param "file"-}
        {-let dest = (drop 1 x) <> "/" <> _file-}
        {-liftIO $ putStrLn dest-}
        {-authCheck (redirect "/login") $ file dest-}

{-conf :: SessionConfig-}
{-conf = defaultSessionConfig-}

-- the defaultSessionConfig is 120 sec to expire, change it to 1 day
mySessionConfig :: SessionConfig
mySessionConfig = SessionConfig "sessions.sqlite3" 1200 86400 False
conf = mySessionConfig

insertFile :: FilePath -> String -> IO ()
insertFile filePath str = do
    content <- D.readFile filePath
    D.writeFile filePath $ (BSC.pack str) <> content

insertFileWithByteString :: FilePath -> D.ByteString -> IO ()
insertFileWithByteString filePath byteString = do 
    content <- D.readFile filePath 
    D.writeFile filePath $ byteString <> content

{- listDirectoryAscendingByTime "Downloads/" -}
listDirectoryAscendingByTime :: FilePath -> IO [FilePath]
listDirectoryAscendingByTime path = do
    filelist <- listDirectory path
    tl <- traverse getModificationTime $ (path <>) <$> filelist
    let fl = reverse $ fst <$> (DL.sortOn snd $ zipWith (,) filelist tl)
    {- print $ fl -}
    return fl

generatePasteHtml :: String -> IO ()
generatePasteHtml pathName = do
        let fileName = pathName <> ".html"
        writeFile fileName $ "<html lang=\"zh-CN\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">  <title>" <> pathName <> "</title>\n </head>\n <body>\n"
        appendFile fileName $ "<form id='myForm' enctype=\"multipart/form-data\" action=\"/" <> pathName <> "\" method=\"post\">"
        appendFile fileName $ "<textarea id=\"formData\" rows=\"6\" cols=\"36\" name=\"" <> pathName <> "\"></textarea> <br> <input onclick=\"clearForm()\" type=\"submit\" value=\"Submit\"> </form> <br>"
        appendFile fileName $ "<script> function clearForm() { var fm = document.getElementById('myForm')[0]; fm.submit(); fm.reset(); document.getElementById('formData').value = '';}; if (window.history.replaceState) {windows.history.replaceState(null, null, window.location.href)} </script>"
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



{- generateFilePondHtml "chunk" -}
generateFilePondHtml :: String -> IO ()
generateFilePondHtml pathName = do
        --_fileList <- getDirectoryContents pathName
        {- _fileList <- listDirectory pathName -}
        _fileList <- listDirectoryAscendingByTime $ pathName <> "/"
        --let fileList = DL.sort _fileList
        --let fileList = [".", ".."] <> (filter (== "..") $ filter (== ".") _fileList)
        let fileList = [".", ".."] <> _fileList
        let fileName = pathName <> ".html"
        writeFile fileName ""
        appendFile fileName $ "<html lang=\"en-US\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> <title>" <> pathName <> "</title>\n <link href=\"https://unpkg.com/filepond/dist/filepond.css\" rel=\"stylesheet\" />\n <script src=\"https://unpkg.com/filepond/dist/filepond.js\"></script>\n </head>\n <body>\n"
        appendFile fileName $ "<input type=\"file\" multiple><br><br><br>\n" 
        appendFile fileName $ foldl1 (<>) (fmap (\x -> "<a href=\"" <> pathName <> "/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList)
        -- traverse (\x -> liftIO $ appendFile "uploadFile.html" $ "<a href=\"uploadFile/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList
        appendFile fileName $ "</body>\n <script> const inputElement = document.querySelector('input[type=\"file\"]'); const pond = FilePond.create( inputElement ); pond.setOptions({ server: \"/" <> pathName <> "\" }) </script> </html>\n" 



postAndShow :: String -> ScottyM ()
postAndShow pathName =
    post (capture pathName) $ authCheck (redirect "/login") $ do
        _files <- files
        traverse (\_file -> liftIO $ DB.writeFile ((DTL.unpack $ fst _file) <> "/" <> (BSC.unpack $ fileName $ snd _file)) (fileContent $ snd _file)) _files
        traverse (\_file -> liftIO $ generateIndexHtml (DTL.unpack $ fst _file)) _files
        liftIO $ print $ pathName <> " upload done"
        file $ (drop 1 pathName) <> ".html"

{- postChunkedData "chunk" -}
postChunkedData :: String -> ScottyM ()
postChunkedData pathName =
    post (capture $ "/" <> pathName) $ authCheck (redirect "/login") $ do
        {- https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition -}
        agent <- header "Content-Disposition"
        {- normal behavior, Content-Disposition in header, not body, for example, python requests -}
        {-Just "form-data; name=\"myFile\"; filename=\"30.Conins.mp4\""-}
        let filename = pathName <> "/" <> (DL.init $ DL.tail $ DTL.unpack $ DL.last $ DTL.splitOn "filename=" $ fromJust agent)
        liftIO $ print $ "uploading file " <> filename
        liftIO $ writeFile filename ""
        {- https://github.com/scotty-web/scotty/blob/master/examples/bodyecho.hs -}
        wb <- body -- this must happen before first 'rd'
        rd <- bodyReader
        let step acc = do 
              chunk <- rd
              let len = D.length chunk
              putStrLn $ "got a chunk, size is " <> (show len) <> " write into " <> filename
              if len > 0 
                then do
                    liftIO $ D.appendFile filename chunk
                    step $ acc + len
                else return acc
        len <- liftIO $ step 0
        {- text $ DTL.pack $ "uploaded " ++ show len ++ " bytes, wb len is " ++ show (DB.length wb) -}
        liftIO $ generateIndexHtml pathName
        file (pathName <> ".html")


{- postChunkedDataFromFilePond "chunk" -}
postChunkedDataFromFilePond :: String -> ScottyM ()
postChunkedDataFromFilePond pathName =
    post (capture $ "/" <> pathName) $ authCheck (redirect "/login") $ do
        wb <- body -- this must happen before first 'rd'
        rd <- bodyReader
        {- https://github.com/pqina/filepond -}
        {- filepond use a head and a tail wrap up all the binary data, -}
        {- and file name in the wrapped header -}

        {- different pond.setOptions will get diffrent wrapped header -}
        {- pond.setOptions({ server: "/chunk" }) -}
        {- "------WebKitFormBoundaryhiD3BuGheYxO5rgG\r\nContent-Disposition: form-data; name=\"filepond\"\r\n\r\n{}\r\n------WebKitFormBoundaryhiD3BuGheYxO5rgG\r\nContent-Disposition: form-data; name=\"filepond\"; filename=\"t.sh\"\r\nContent-Type: application/x-shellscript\r\n\r\ndata\r\n------WebKitFormBoundaryhiD3BuGheYxO5rgG--\r\n" -}

        {- pond.setOptions({  -}
            {- server: { -}
                {- process: (fieldName, file, metadata, load, error, progress, abort, transfer, options) => { -}
                    {- const formData = new FormData(); -}
                    {- formData.append(fieldName, file, file.name); -}
                    {- const request = new XMLHttpRequest(); -}
                    {- request.open('POST', '/chunk'); -}
                    {- request.setRequestHeader("Content-Disposition","form-data; name=\"filepond\"; filename=\"" + file.name + "\"") -}
                    {- request.upload.onprogress = (e) => { -}
                        {- progress(e.lengthComputable, e.loaded, e.total); -}
                    {- }; -}
                    {- request.onload = function () { -}
                        {- if (request.status >= 200 && request.status < 300) { -}
                            {- load(request.responseText); -}
                        {- } else { -}
                            {- error('oh no'); -}
                        {- } -}
                    {- }; -}
                    {- request.send(formData); -}
                    {- return { -}
                        {- abort: () => { -}
                            {- request.abort(); -}
                            {- abort(); -}
                        {- }, -}
                    {- }; -}
                {- }, -}
            {- }, -}
        {- }); -}

        {- "------WebKitFormBoundary0CA7T97lFhwGdtTF\r\nContent-Disposition: form-data; name=\"filepond\"; filename=\"t.sh\"\r\nContent-Type: application/x-shellscript\r\n\r\ndata\r\n------WebKitFormBoundary0CA7T97lFhwGdtTF--\r\n" -}

        let firstChunk = do
                    chunk <- rd
                    return chunk
        chunk1 <- liftIO $ firstChunk

        let filename = pathName <> "/" <> (DL.init $ DL.tail $ show $ D.drop 10 $ fst $ D.breakSubstring "\"\r\n" $ snd $ D.breakSubstring "filename" chunk1)
        let webKitFormBoundary = fst $ D.breakSubstring "\r\n" chunk1
        {- since breakSubstring will only break first one, and metadata \r\n\r\n at the first,so it's ok -}
        {- breakSubstring "bc" "abc1whatabc2" == ("a","bc1whatabc2") -}

        {- let realFileStart = D.drop 4 $ snd $ D.breakSubstring "\r\n\r\n" chunk1 -}
        let realFileStart = D.drop 4 $ snd $ D.breakSubstring "\r\n\r\n" $ snd $ D.breakSubstring "filename" chunk1

        let step filename lastChunk = do 
              chunk <- rd
              let len = D.length chunk
              {- putStrLn $ "got a chunk, size is " <> (show len) <> " write into " <> filename -}
              if len > 0 
                then do
                    D.appendFile filename lastChunk
                    step filename chunk
                else return lastChunk

        liftIO $ print $ "uploading file " <> filename
        liftIO $ writeFile filename ""
        lastChunk <- liftIO $ step filename realFileStart

        {- let realFileEnd = fst $ D.breakSubstring "\r\n------WebKitFormBoundary" lastChunk -}
        let realFileEnd = fst $ D.breakSubstring ("\r\n" <> webKitFormBoundary) lastChunk

        liftIO $ D.appendFile filename realFileEnd
        liftIO $ generateFilePondHtml pathName
        file (pathName <> ".html")

main :: IO ()
main = do
    {- traverse generateIndexHtml ["docs", "code", "config", "text", "audio", "video", "picture", "others", "chunk"] -}
    traverse generateIndexHtml ["docs", "code", "config", "text", "audio", "video", "picture", "others"]
    generateFilePondHtml "chunk"
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
    appendFile "index.html" $ foldl1 (<>) (fmap (\x -> "<a href=\"" <> x  <> "\"> " <> x <> "</a> <br> <br> <br>" <> "\n") ["/paste", "/docs", "/config", "/code", "/upload", "/text", "/audio", "/video", "/picture", "/others", "/chunk"])
    appendFile "index.html" "</body>\n </html>\n" 
    
    D.appendFile "paste.txt" $ BSC.pack "\n<br>"

    generatePasteHtml "paste"

    initializeCookieDb conf

    scotty 3000 $ do
        --get "/" $ text "docs, config, code, upload, text, audio, video, picture, others"
        get "/" $ authCheck (redirect "/login") $ file "index.html"
        get "/docs" $ authCheck (redirect "/login") $ file "docs.html"
        get "/code" $ authCheck (redirect "/login") $ file "code.html"
        get "/config" $ authCheck (redirect "/login") $ file "config.html"
        get "/upload" $ authCheck (redirect "/login") $ file "upload.html"
        get "/text" $ authCheck (redirect "/login") $ file "text.html"
        get "/audio" $ authCheck (redirect "/login") $ file "audio.html"
        get "/video" $ authCheck (redirect "/login") $ file "video.html"
        get "/picture" $ authCheck (redirect "/login") $ file "picture.html"
        get "/others" $ authCheck (redirect "/login") $ file "others.html"
        get "/paste" $ authCheck (redirect "/login") $ file "paste.html"
        get "/chunk" $ authCheck (redirect "/login") $ file "chunk.html"
        get "/denied" $ text "access denied"
        get "/login" $ do html $ DTL.pack $ unlines $
                            [ "<form method=\"POST\" action=\"/login\">"
                            , "<label for=\"username\">User:</label> <input type=\"text\" name=\"username\"> <br> <br>"
                            , "<label for=\"password\">Pass:</label> <input type=\"password\" name=\"password\"> <br> <br>"
                            , "<input type=\"submit\" name=\"login\" value=\"login\">"
                            , "</form>" ]
    
        get "/test" $ do 
            agent <- header "User-Agent"
            liftIO $ print agent
            setSimpleCookie "this-is-cookie-name" "b"
            text "hi"
    
        post "/login" $ do
            (usn :: String) <- param "username"
            (pass :: String) <- param "password"
            if usn == "user" && pass == "pass"
                then do 
                    id <- addSession conf
                    liftIO $ print id
                    redirect "/"
                else text "invalid user or wrong password"
    
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
    
        post "/paste" $ authCheck (redirect "/login") $ do
        -- submit form data is post with params
            {-_params <- params-}
            --traverse (\_param -> liftIO $ appendFile ((DTL.unpack $ fst _param) <> ".txt") (DTL.unpack $ (snd _param) <> "\n")) _params
            {-traverse (\_param -> liftIO $ insertFile ((DTL.unpack $ fst _param) <> ".txt") (DTL.unpack $ (snd _param) <> "\n")) _params-}
            binaryData <- param "paste"
            liftIO $ print binaryData
            if (binaryData == BSC.pack "") then liftIO $ print "empty submit"
            else do
                let binaryDataList = BSC.lines binaryData
                liftIO $ insertFileWithByteString "paste.txt" $ BSC.concat $ fmap (<> (BSC.pack "<br>\n")) binaryDataList
                {-liftIO $ D.appendFile "paste.txt" binaryData -}
                {-liftIO $ insertFileWithByteString "paste.txt" $ BSC.pack "\n<br>"-}
                {-liftIO $ insertFileWithByteString "paste.txt" binaryData-}
                {-byteData <- liftIO $ D.readFile "paste.txt"-}
                {-text $ DTL.pack $ BSC.unpack byteData-}
            liftIO $ generatePasteHtml "paste"
            file "paste.html"
    
        postChunkedDataFromFilePond "chunk"

        get "/:file" $ authCheck (redirect "/login") $ do
             _file <- param "file"
             liftIO $ putStrLn $ "visit " <> _file
             file _file
    
        get "/:to/:file" $ authCheck (redirect "/login") $ do
            _to <- param "to"
            _file <- param "file"
            let dest = _to <> "/" <> _file
            liftIO $ putStrLn $ "visit " <> dest
            if _to /= "chunk"
                then file dest
                else do
                    let filePath = _to <> "/" <> _file
                    handle <- liftIO $ openBinaryFile filePath ReadMode
                    stream (\write flush ->
                        let mediaStream handle = do 
                                                    {- isEof <- hIsEOF handle -}
                                                    {- if isEof -}
                                                        {- then return () -}
                                                        {- else do  -}
                                                          {- bytestring <- D.hGet handle 100000 -}
                                                          {- let readSize = D.length bytestring -}
                                                          {- print $ "read chunk size " <> (show readSize) -}
                                                          {- write $ fromByteString bytestring -}
                                                          {- flush -}
                                                          {- hSeek handle RelativeSeek $ toInteger readSize -}
                                                          {- mediaStream handle -}
                                                    bytestring <- D.hGet handle 100000
                                                    {- 100000 mean 100MB, since hGet increase the offset by it read, so no hSeek here -}
                                                    if D.length bytestring == 0
                                                        then return ()
                                                        else do 
                                                          let readSize = D.length bytestring
                                                          {- putStr $ "read chunk size " <> (show readSize) <> ", " -}
                                                          write $ fromByteString bytestring
                                                          flush
                                                          {- hSeek handle RelativeSeek $ toInteger readSize -}
                                                          {- hSeek handle RelativeSeek 100000 -}
                                                          count <- hTell handle
                                                          {- print $ show count -}
                                                          mediaStream handle
                        in mediaStream handle)

        get "/:path/:to/:file" $ authCheck (redirect "/login") $ do
            _path <- param "path"
            _to <- param "to"
            _file <- param "file"
            let dest = _path <> "/" <> _to <> "/" <> _file
            liftIO $ putStrLn $ "visit " <> dest
            file $ dest
    
        get "/:path/:to/:file/:r1" $ authCheck (redirect "/login") $ do
            _path <- param "path"
            _to <- param "to"
            _file <- param "file"
            _r1 <- param "r1"
            let dest = _path <> "/" <> _to <> "/" <> _file <> "/" <> _r1
            liftIO $ putStrLn $ "visit " <> dest
            file $ dest

        get "/:path/:to/:file/:r1/:r2" $ authCheck (redirect "/login") $ do
            _path <- param "path"
            _to <- param "to"
            _file <- param "file"
            _r1 <- param "r1"
            _r2 <- param "r2"
            let dest = _path <> "/" <> _to <> "/" <> _file <> "/" <> _r1 <> "/" <> _r2
            liftIO $ putStrLn $ "visit " <> dest
            file $ dest

        get "/:path/:to/:file/:r1/:r2/:r3" $ authCheck (redirect "/login") $ do
            _path <- param "path"
            _to <- param "to"
            _file <- param "file"
            _r1 <- param "r1"
            _r2 <- param "r2"
            _r3 <- param "r3"
            let dest = _path <> "/" <> _to <> "/" <> _file <> "/" <> _r1 <> "/" <> _r2 <> "/" <> _r3
            liftIO $ putStrLn $ "visit " <> dest
            file $ dest

        get "/:path/:to/:file/:r1/:r2/:r3/:r4" $ authCheck (redirect "/login") $ do
            _path <- param "path"
            _to <- param "to"
            _file <- param "file"
            _r1 <- param "r1"
            _r2 <- param "r2"
            _r3 <- param "r3"
            _r4 <- param "r4"
            let dest = _path <> "/" <> _to <> "/" <> _file <> "/" <> _r1 <> "/" <> _r2 <> "/" <> _r3 <> "/" <> _r4
            liftIO $ putStrLn $ "visit " <> dest
            file $ dest

        get "/:path/:to/:file/:r1/:r2/:r3/:r4/:r5" $ authCheck (redirect "/login") $ do
            _path <- param "path"
            _to <- param "to"
            _file <- param "file"
            _r1 <- param "r1"
            _r2 <- param "r2"
            _r3 <- param "r3"
            _r4 <- param "r4"
            _r5 <- param "r5"
            let dest = _path <> "/" <> _to <> "/" <> _file <> "/" <> _r1 <> "/" <> _r2 <> "/" <> _r3 <> "/" <> _r4 <> "/" <> _r5
            liftIO $ putStrLn $ "visit " <> dest
            file $ dest

        get "/:path/:to/:file/:r1/:r2/:r3/:r4/:r5/:r6" $ authCheck (redirect "/login") $ do
            _path <- param "path"
            _to <- param "to"
            _file <- param "file"
            _r1 <- param "r1"
            _r2 <- param "r2"
            _r3 <- param "r3"
            _r4 <- param "r4"
            _r5 <- param "r5"
            _r6 <- param "r6"
            let dest = _path <> "/" <> _to <> "/" <> _file <> "/" <> _r1 <> "/" <> _r2 <> "/" <> _r3 <> "/" <> _r4 <> "/" <> _r5 <> "/" <> _r6
            liftIO $ putStrLn $ "visit " <> dest
            file $ dest

        {-getFile ["docs", "code", "config", "text", "audio", "video", "picture", "others"]-}
        {-return ()-}
