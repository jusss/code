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
import System.Process
import System.Posix.Files
import Data.Maybe
import Data.Binary.Builder
import Data.Text.Lazy.Encoding
import Data.Time.Clock
import Data.Time.Clock.POSIX
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

rootPath = "/root/web"
{- all directory html should be in rootPath/html/, visit /docs/dir/ should file rootPath/html/docs/dir/index.html, vist /docs/file should file rootPath/docs/file, avoid access /html directory -}
accessPoint = ["paste", "docs", "config", "code", "upload", "text", "audio", "video", "picture", "others", "chunk", "node_modules"]
pathLevel = scanl1 (<>) $ fmap (("/:" <>) . ("l" <>) . show) [1..9]

-- the defaultSessionConfig is 120 sec to expire, change it to 1 day
sessionConfig :: SessionConfig
sessionConfig = SessionConfig "sessions.sqlite3" 1200 86400 False

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
    return fl

generateVideoHtml :: String -> IO String
generateVideoHtml pathName = do
        createDirectoryIfMissing True $ rootPath <> "/html/" <> pathName
        createDirectoryIfMissing True $ rootPath <> "/" <> pathName
        fileList <- listDirectoryAscendingByTime $ rootPath <> "/" <> pathName <> "/"
        let fileName = rootPath <> "/html/" <> pathName <> "/index.html"
        writeFile fileName $ "<html lang=\"zh-CN\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">  <title>" <> pathName <> "</title>\n </head>\n <body>\n"
        appendFile fileName $ "<button onclick=\"history.back()\">Go Back</button><br><br>"
        appendFile fileName $ "<form id='myForm' enctype=\"multipart/form-data\" action=\"/" <> pathName <> "\" method=\"post\">"
        appendFile fileName $ "<textarea id=\"formData\" rows=\"6\" cols=\"36\" name=\"" <> pathName <> "\"></textarea> <br> <input onclick=\"clearForm()\" type=\"submit\" value=\"Submit\"> </form> <br>"
        if null fileList then return ()
        else appendFile fileName $ foldl1 (<>) (fmap (\x -> "<a href=\"" <> pathName <> "/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList)
        appendFile fileName $ "<script> function clearForm() { var fm = document.getElementById('myForm')[0]; fm.submit(); fm.reset(); document.getElementById('formData').value = '';}; if (window.history.replaceState) {windows.history.replaceState(null, null, window.location.href)} </script>"
        appendFile fileName "</body>\n </html>\n" 
        return fileName

generatePasteHtml :: String -> IO String
generatePasteHtml pathName = do
        createDirectoryIfMissing True $ rootPath <> "/html/" <> pathName
        createDirectoryIfMissing True $ rootPath <> "/" <> pathName
        isExist <- doesFileExist $ rootPath <> "/" <> pathName <> "/paste.txt"
        if isExist then return ()
        else D.appendFile (rootPath <> "/" <> pathName <> "/paste.txt") $ BSC.pack "\n<br>"
        let fileName = rootPath <> "/html/" <> pathName <> "/index.html"
        writeFile fileName $ "<html lang=\"zh-CN\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">  <title>" <> pathName <> "</title>\n </head>\n <body>\n"
        appendFile fileName $ "<button onclick=\"history.back()\">Go Back</button><br><br>"
        appendFile fileName $ "<form id='myForm' enctype=\"multipart/form-data\" action=\"/" <> pathName <> "\" method=\"post\">"
        appendFile fileName $ "<textarea id=\"formData\" rows=\"6\" cols=\"36\" name=\"" <> pathName <> "\"></textarea> <br> <input onclick=\"clearForm()\" type=\"submit\" value=\"Submit\"> </form> <br>"
        appendFile fileName $ "<script> function clearForm() { var fm = document.getElementById('myForm')[0]; fm.submit(); fm.reset(); document.getElementById('formData').value = '';}; if (window.history.replaceState) {windows.history.replaceState(null, null, window.location.href)} </script>"
        byteData <- D.readFile $ rootPath <> "/" <> pathName <> "/paste.txt"
        D.appendFile fileName byteData
        appendFile fileName "</body>\n </html>\n" 
        return fileName

{- generateFilePondHtml "chunk" -}
generateFilePondHtml :: String -> IO String
generateFilePondHtml pathName = do
        fileList <- listDirectoryAscendingByTime $ rootPath <> "/" <> pathName <> "/"
        createDirectoryIfMissing True $ rootPath <> "/html/" <> pathName
        createDirectoryIfMissing True $ rootPath <> "/" <> pathName
        let fileName = rootPath <> "/html/" <> pathName <> "/index.html"
        writeFile fileName ""
        appendFile fileName $ "<html lang=\"en-US\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> <title>" <> pathName <> "</title>\n <link href=\"node_modules/filepond/dist/filepond.css\" rel=\"stylesheet\" />\n <script src=\"node_modules/filepond/dist/filepond.js\"></script>\n </head>\n <body>\n"
        appendFile fileName $ "<button onclick=\"history.back()\">Go Back</button><br><br>"
        appendFile fileName $ "<input type=\"file\" multiple><br><br><br>\n" 
        if null fileList then return ()
        else appendFile fileName $ foldl1 (<>) (fmap (\x -> "<a href=\"" <> pathName <> "/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList)
        -- traverse (\x -> liftIO $ appendFile "uploadFile.html" $ "<a href=\"uploadFile/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList
        appendFile fileName $ "</body>\n <script> const inputElement = document.querySelector('input[type=\"file\"]'); const pond = FilePond.create( inputElement ); pond.setOptions({ server: \"/" <> pathName <> "\" }) </script> </html>\n" 
        return fileName

{- there are three post ways, postAndShow is simple post whole file at once, postChunkedData is post with chunk, postChunkedDataFromFilePond is post with filepond, other function see previous version web6.hs -}
{- postChunkedDataFromFilePond "chunk" -}
postChunkedDataFromFilePond :: String -> ScottyM ()
postChunkedDataFromFilePond pathName =
    post (capture $ "/" <> pathName) $ authCheck (redirect "/login") $ do
        wb <- body -- this must happen before first 'rd'
        rd <- bodyReader
        let firstChunk = do
                    chunk <- rd
                    return chunk
        chunk1 <- liftIO $ firstChunk
        let filename = pathName <> "/" <> (DL.init $ DL.tail $ show $ D.drop 10 $ fst $ D.breakSubstring "\"\r\n" $ snd $ D.breakSubstring "filename" chunk1)
        let webKitFormBoundary = fst $ D.breakSubstring "\r\n" chunk1
        let realFileStart = D.drop 4 $ snd $ D.breakSubstring "\r\n\r\n" $ snd $ D.breakSubstring "filename" chunk1
        let step filename lastChunk = do 
              chunk <- rd
              let len = D.length chunk
              if len > 0 
                then do
                    D.appendFile filename lastChunk
                    step filename chunk
                else return lastChunk

        liftIO $ print $ "uploading file " <> filename
        liftIO $ writeFile filename ""
        lastChunk <- liftIO $ step filename realFileStart
        let realFileEnd = fst $ D.breakSubstring ("\r\n" <> webKitFormBoundary) lastChunk
        liftIO $ D.appendFile filename realFileEnd
        file =<< (liftIO $ generateFilePondHtml pathName)

generateHtmlForDirectory :: String -> IO String
generateHtmlForDirectory pathName = do
        -- it's important, only the last level in the html, when you in chunk directory, and html has chunk/a, click it, it will visit chunk/chunk/a
        let lastLevel = DTL.unpack $ DL.last $ DTL.splitOn "/" $ DTL.pack pathName
        fileList <- listDirectory pathName
        -- generate directory html in /root/web/html/, not same path where file path is
        let fileName = rootPath <> "/html/" <> pathName <> "/index.html"
        createDirectoryIfMissing True $ rootPath <> "/html/" <> pathName
        print $ "generate " <> fileName
        writeFile fileName " "
        appendFile fileName $ "<html lang=\"en-US\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> <title>" <> pathName <> "</title>\n </head>\n <body>\n"
        appendFile fileName $ "<button onclick=\"history.back()\">Go Back</button><br><br>"
        -- appendFile fileName $ foldl1 (<>) (fmap (\x -> "<a href=\"" <> pathName <> "/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList)
        if null fileList then return ()
        else appendFile fileName $ foldl1 (<>) (fmap (\x -> "<a href=\"" <> lastLevel <> "/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList)
        appendFile fileName "</body>\n </html>\n" 
        return fileName

getChunkedData filePath = do
    fileStatus <- liftIO $ getFileStatus filePath 
    let _isDir = isDirectory fileStatus
    if _isDir then file =<< (liftIO $ generateHtmlForDirectory filePath)
    else do
        handle <- liftIO $ openBinaryFile filePath ReadMode
        stream (\write flush ->
            let mediaStream handle = do 
                                        bytestring <- D.hGet handle 100000
                                        {- 100000 mean 100MB, since hGet increase the offset by it read, so no hSeek here -}
                                        if D.length bytestring == 0
                                            then return ()
                                            else do 
                                              let readSize = D.length bytestring
                                              write $ fromByteString bytestring
                                              flush
                                              count <- hTell handle
                                              mediaStream handle
            in mediaStream handle)

showContent filePath = do
    let _pathList = DL.filter (/= "") $ DTL.splitOn "/:" filePath
    pathList <- traverse param _pathList
    -- limit the access
    if (head pathList) `notElem` accessPoint then text "not found"
    else do
        let dest = DL.init $ DL.foldl1 (<>) $ fmap (<> "/") pathList
        liftIO $ print $ "showContent, visit " <> dest
        isExist <- liftIO $ fileExist dest
        if isExist then getChunkedData dest
        else text "not found"

generateHomePageHtml :: String -> IO String
generateHomePageHtml rootPath = do
    let fileName = rootPath <> "/html/index.html"
    writeFile fileName " "
    appendFile fileName $ "<html lang=\"en-US\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> <title> index </title>\n </head>\n <body>\n"
    appendFile fileName $ foldl1 (<>) (fmap (\x -> "<a href=\"" <> x  <> "\"> " <> x <> "</a> <br> <br> <br>" <> "\n") ["/paste", "/docs", "/config", "/code", "/upload", "/text", "/audio", "/video", "/picture", "/others", "/chunk"])
    return fileName

main :: IO ()
main = do
    initializeCookieDb sessionConfig
    scotty 3000 $ do
        get "/" $ authCheck (redirect "/login") $ file =<< (liftIO $ generateHomePageHtml rootPath)
        get "/video" $ authCheck (redirect "/login") $ file =<< (liftIO $ generateVideoHtml "video")
        get "/paste" $ authCheck (redirect "/login") $ file =<< (liftIO $ generatePasteHtml "paste")
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
        {- get first level  -}
        traverse (\path -> get (capture ("/" <> path)) $ authCheck (redirect "/login") $ file =<< (liftIO $ generateFilePondHtml path)) ["upload", "text", "audio", "picture", "others", "chunk"]
        {- get arbitrary level -}
        traverse (\path -> get (capture path) $ authCheck (redirect "/login") $ showContent (DTL.pack path)) pathLevel
    
        post "/login" $ do
            (usn :: String) <- param "username"
            (pass :: String) <- param "password"
            if usn == "user" && pass == "pass"
                then do 
                    id <- addSession sessionConfig
                    liftIO $ print id
                    redirect "/"
                else text "invalid user or wrong password"

        post "/paste" $ authCheck (redirect "/login") $ do
            binaryData <- param "paste"
            liftIO $ print binaryData
            if (binaryData == BSC.pack "") then liftIO $ print "empty submit"
            else do
                let binaryDataList = BSC.lines binaryData
                liftIO $ insertFileWithByteString (rootPath <> "/paste/paste.txt") $ BSC.concat $ fmap (<> (BSC.pack "<br>\n")) binaryDataList
            file =<< (liftIO $ generatePasteHtml "paste")

        post "/video" $ authCheck (redirect "/login") $ do
            binaryData <- param "video"
            liftIO $ print binaryData
            if (binaryData == BSC.pack "") then liftIO $ print "empty submit"
            else do
                _d <- liftIO $ getCurrentTime
                let _date = fmap (\x -> if x == ' ' then '.' else x) $ DL.take 19 $ show _d
                liftIO $ callCommand ("cd video; youtube-dl --no-mtime -o '" <> _date <> ".%(ext)s' " <> (BSC.unpack binaryData))
            file =<< (liftIO $ generateVideoHtml "video")

        {- post first level -}
        traverse postChunkedDataFromFilePond ["upload", "text", "audio", "picture", "others", "chunk"]
        return ()
