{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
import Network.Wai
import Network.Wai.Parse
import Network.HTTP.Types
import Network.Wai.Handler.Warp (run)
import Web.Scotty
import Web.Scotty.Login.Session
import Web.Scotty.Cookie
import Web.Scotty.TLS
import Control.Monad
import Control.Monad.IO.Class
import Control.Monad.Trans.Cont
import Control.Exception
import System.Environment
import System.Directory
import System.IO
import System.Process
import System.Posix.Files
import Data.Maybe
import Data.Binary.Builder
import Data.Text.Lazy.Encoding
import qualified Data.Text.Encoding as DTE
import Data.Text.Encoding.Error
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
import Language.Javascript.JSaddle.String

{- no more html file, just html strings for directory -}
{- there're urlPath like /a/b and filePath like rootPath <> urlPath -}
rootPath = "/root/web"
accessPoint = ["/paste", "/docs", "/config", "/code", "/upload", "/text", "/audio", "/video", "/picture", "/others", "/chunk", "/node_modules"]
routePatternList = scanl1 (<>) $ fmap (("/:" <>) . ("l" <>) . show) [1..9]
{- do not show visit path on console -}
doNotShowPath = ["/favicon.ico", "/node_modules/filepond/dist/filepond.css", "/node_modules/filepond/dist/filepond.js"]

{- in order to show text with utf8 in get request,  -}
{- addHeader "Content-Type" "text/plain; charset=utf-8", for file -}
{- addHeader "Content-Type" "text/html; charset=utf-8", for directory html string -}

-- the defaultSessionConfig is 120 sec to expire, change it to 1 day
sessionConfig :: SessionConfig
sessionConfig = SessionConfig "sessions.sqlite3" 1200 86400 False

insertFileWithByteString :: FilePath -> D.ByteString -> IO ()
insertFileWithByteString filePath byteString = do 
    content <- D.readFile filePath 
    D.writeFile filePath $ byteString <> content

listDirectoryAscendingByTime :: FilePath -> IO [FilePath]
listDirectoryAscendingByTime path = do
    filelist <- listDirectory path
    tl <- traverse getModificationTime $ ((path <> "/") <>) <$> filelist
    let fl = reverse $ fst <$> (DL.sortOn snd $ zipWith (,) filelist tl)
    return fl

generateVideoHtml :: String -> ActionM ()
generateVideoHtml pathName = do
        addHeader "Content-Type" "text/html; charset=utf-8"
        liftIO $ print $ "get " <> pathName
        liftIO $ createDirectoryIfMissing True $ rootPath <> pathName
        fileList <- liftIO $ listDirectoryAscendingByTime $ rootPath <> pathName
        let h0 = "<html lang=\"zh-CN\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">  <title>" <> pathName <> "</title>\n </head>\n <body>\n"
        let h1 = "<a href=\"/\">home</a><br><br>"
        let h2 = "<form id='myForm' enctype=\"multipart/form-data\" action=\"" <> pathName <> "\" method=\"post\">"
        let h3 = "<textarea id=\"formData\" rows=\"6\" cols=\"36\" name=\"" <> pathName <> "\"></textarea> <br> <input onclick=\"clearForm()\" type=\"submit\" value=\"Submit\"> </form> <br>"
        let h4 = if null fileList then "" else foldl1 (<>) (fmap (\x -> "<a href=\"" <> pathName <> "/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList)
        let h5 = "<script> function clearForm() { var fm = document.getElementById('myForm')[0]; fm.submit(); fm.reset(); document.getElementById('formData').value = '';}; if (window.history.replaceState) {windows.history.replaceState(null, null, window.location.href)} </script>"
        let h6 = "</body>\n </html>\n" 
        html $ DTL.pack $ h0 <> h1 <> h2 <> h3 <> h4 <> h5 <> h6

generatePasteHtml :: String -> ActionM ()
generatePasteHtml pathName = do
        addHeader "Content-Type" "text/html; charset=utf-8"
        liftIO $ print $ "get " <> pathName
        liftIO $ createDirectoryIfMissing True $ rootPath <> pathName
        isExist <- liftIO $ doesFileExist $ rootPath <> pathName <> "/paste.txt"
        if isExist then return ()
        else liftIO $ D.appendFile (rootPath <> pathName <> "/paste.txt") $ BSC.pack "\n<br>"
        let h0 = "<html lang=\"zh-CN\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">  <title>" <> pathName <> "</title>\n </head>\n <body>\n"
        let h1 = "<a href=\"/\">home</a><br><br>"
        let h2 = "<form id='myForm' enctype=\"multipart/form-data\" action=\"" <> pathName <> "\" method=\"post\">"
        let h3 = "<textarea id=\"formData\" rows=\"6\" cols=\"36\" name=\"" <> pathName <> "\"></textarea> <br> <input onclick=\"clearForm()\" type=\"submit\" value=\"Submit\"> </form> <br>"
        let h4 = "<script> function clearForm() { var fm = document.getElementById('myForm')[0]; fm.submit(); fm.reset(); document.getElementById('formData').value = '';}; if (window.history.replaceState) {windows.history.replaceState(null, null, window.location.href)} </script>"
        binaryData <- liftIO $ D.readFile $ rootPath <> pathName <> "/paste.txt"
        let h5 = concat $ fmap (<> "<br>") $ lines $ DT.unpack $ DTE.decodeUtf8With lenientDecode binaryData
        {- let f = rootPath <> "/" <> pathName <> "/paste.txt" -}
        {- strOrException <- catch (readFile f) -}
                            {- (\e -> do  -}
                                    {- let err = show (e :: IOException) -}
                                    {- hPutStr stderr ("Warning: Couldn't open " ++ f ++ ": " ++ err) -}
                                    {- return "") -}
        {- strOrException <- catch (readFile $ rootPath <> "/" <> pathName <> "/paste.txt") (\e -> return $ show (e :: IOException)) -}
        {- print strOrException -}
        {- let h5 = strOrException -}
        let h6 = "</body>\n </html>\n" 
        html $ DTL.pack $ h0 <> h1 <> h2 <> h3 <> h4 <> h5 <> h6

generateFilePondHtml :: String -> ActionM ()
generateFilePondHtml pathName = do
        addHeader "Content-Type" "text/html; charset=utf-8"
        liftIO $ print $ "get " <> pathName
        fileList <- liftIO $ listDirectoryAscendingByTime $ rootPath <> pathName
        liftIO $ createDirectoryIfMissing True $ rootPath <> pathName
        let h0 = "<html lang=\"en-US\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> <title>" <> pathName <> "</title>\n <link href=\"/node_modules/filepond/dist/filepond.css\" rel=\"stylesheet\" />\n <script src=\"/node_modules/filepond/dist/filepond.js\"></script>\n </head>\n <body>\n"
        {- let h1 = "<button onclick=\"history.back()\">Go Back</button><br><br>" -}
        let h1 = "<a href=\"/\">home</a><br><br>"
        let h2 = "<input type=\"file\" multiple><br><br><br>\n" 
        let h3 = if null fileList then "" else foldl1 (<>) (fmap (\x -> "<a href=\"" <> pathName <> "/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList)
        let h4 = "</body>\n <script> const inputElement = document.querySelector('input[type=\"file\"]'); const pond = FilePond.create( inputElement ); pond.setOptions({ server: \"" <> pathName <> "\" }) </script> </html>\n" 
        html $ DTL.pack $ h0 <> h1 <> h2 <> h3 <> h4

generateTextHtml :: String -> ActionM ()
generateTextHtml urlPath = do
        addHeader "Content-Type" "text/html; charset=utf-8"
        liftIO $ print $ "get " <> urlPath
        fileList <- liftIO $ listDirectoryAscendingByTime $ rootPath <> urlPath
        liftIO $ createDirectoryIfMissing True $ rootPath <> urlPath
        let h0 = "<html lang=\"en-US\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> <title>" <> urlPath <> "</title>\n <link href=\"/node_modules/filepond/dist/filepond.css\" rel=\"stylesheet\" />\n <script src=\"/node_modules/filepond/dist/filepond.js\"></script>\n </head>\n <body>\n"
        {- let h1 = "<button onclick=\"history.back()\">Go Back</button><br><br>" -}
        let h1 = "<a href=\"/\">home</a><br><br>"

        {- let hf = "<form action=\"" <> urlPath <> "\"  method=\"post\"> <label for=\"fileName\">New File:</label> <input type=\"text\" name=\"newFile\"><input type=\"submit\" value=\"Create\"></form>" -}
        let hf = "<form action=\"" <> urlPath <> "/create" <> "\"  method=\"post\"> <label for=\"fileName\">New File:</label> <input type=\"text\" name=\"newFile\" value=\"\"><input type=\"submit\" value=\"Create\"></form>"

        let h2 = "<input type=\"file\" multiple><br><br><br>\n" 
        let h3 = if null fileList then "" else foldl1 (<>) (fmap (\x -> "<a href=\"" <> urlPath <> "/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList)
        let h4 = "</body>\n <script> const inputElement = document.querySelector('input[type=\"file\"]'); const pond = FilePond.create( inputElement ); pond.setOptions({ server: \"" <> urlPath <> "\" }) </script> </html>\n" 
        html $ DTL.pack $ h0 <> h1 <> hf <> h2 <> h3 <> h4

{- there are three post ways, postAndShow is simple post whole file at once, postChunkedData is post with chunk, postChunkedDataFromFilePond is post with filepond, other function see previous version web6.hs -}
{- https://www.haskellforall.com/2012/12/the-continuation-monad.html -}
{- runContT (postChunkedDataFromFilePond pathName) generateFilePondHtml -}
postChunkedDataFromFilePond :: String -> ContT () ActionM String
postChunkedDataFromFilePond pathName = ContT $ \afterPostGenerateHtml -> do
        liftIO $ print $ "post " <> pathName
        wb <- body -- this must happen before first 'rd'
        rd <- bodyReader
        let firstChunk = do
                    chunk <- rd
                    return chunk
        chunk1 <- liftIO $ firstChunk
        let filename = rootPath <> pathName <> "/" <> (DL.init $ DL.tail $ show $ D.drop 10 $ fst $ D.breakSubstring "\"\r\n" $ snd $ D.breakSubstring "filename" chunk1)
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
        afterPostGenerateHtml pathName

generateHtmlForDirectory :: String -> ActionM ()
generateHtmlForDirectory pathName = do
        addHeader "Content-Type" "text/html; charset=utf-8"
        -- it's important, only the last level in the html, when you in chunk directory, and html has chunk/a, click it, it will visit chunk/chunk/a
        -- so use absolute path /chunk/a, or just relative path just the last level a in the html
        let lastLevel = DTL.unpack $ DL.last $ DTL.splitOn "/" $ DTL.pack pathName
        fileList <- liftIO $ listDirectory $ rootPath <> pathName
        let h0 = "<html lang=\"en-US\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> <title>" <> pathName <> "</title>\n </head>\n <body>\n"
        {- let h1 = "<button onclick=\"history.back()\">Go Back</button><br><br>" -}
        let h1 = "<a href=\"/\">home</a><br><br>"
        {- let h2 = if null fileList then "" else foldl1 (<>) (fmap (\x -> "<a href=\"" <> lastLevel <> "/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList) -}
        let h2 = if null fileList then "" else foldl1 (<>) (fmap (\x -> "<a href=\"" <> pathName <> "/" <> x <> "\"> " <> x <> "</a> <br>" <> "\n") fileList)
        let h3 = "</body>\n </html>\n" 
        html $ DTL.pack $ h0 <> h1 <> h2 <> h3

getChunkedFile :: String -> ActionM ()
getChunkedFile urlPath = do
        addHeader "Content-Type" "text/plain; charset=utf-8"
        handle <- liftIO $ openBinaryFile (rootPath <> urlPath) ReadMode
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

getTextFile :: String -> ActionM ()
getTextFile urlPath = do
        addHeader "Content-Type" "text/html; charset=utf-8"
        let fileName = DTL.unpack $ DL.last $ DTL.splitOn "/" $ DTL.pack urlPath
        let urlDirectory = concat $ fmap (("/" <> ) . DTL.unpack) $ DL.init $ DL.filter (/= "") $ DTL.splitOn "/" $ DTL.pack urlPath
        let h0 = "<html lang=\"zh-CN\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">  <title>" <> fileName <> "</title>\n </head>\n <body>\n"
        let h1 = "<a href=\"/\">home</a><br><br>"
        let hb = "<a href=\"" <> urlDirectory <> "\">back</a><br><br>"
        let hf = "<form action=\"" <> urlPath <> "\"  method=\"post\">  <input type=\"hidden\" name=\"mode\" value=\"append\"> <button name=\"" <> urlPath <> "\" value=\"edit\">edit</button></form>"
        let h2 = "<form id='myForm' enctype=\"multipart/form-data\" action=\"" <> urlPath <> "\" method=\"post\">"
        let h2_ = "<input type=\"hidden\" name=\"mode\" value=\"append\">"
        let h3 = "<textarea id=\"formData\" rows=\"6\" cols=\"36\" name=\"" <> urlPath <> "\"></textarea> <br> <input onclick=\"clearForm()\" type=\"submit\" value=\"Submit\"> </form> <br>"
        let h4 = "<script> function clearForm() { var fm = document.getElementById('myForm')[0]; fm.submit(); fm.reset(); document.getElementById('formData').value = '';}; if (window.history.replaceState) {windows.history.replaceState(null, null, window.location.href)} </script>"
        binaryData <- liftIO $ D.readFile $ rootPath <> urlPath
        let h5 = concat $ fmap (<> "<br>") $ lines $ DT.unpack $ DTE.decodeUtf8With lenientDecode binaryData
        let h6 = "</body>\n </html>\n" 
        html $ DTL.pack $ h0 <> h1 <> hb <> hf <> h2 <> h2_ <> h3 <> h4 <> h5 <> h6

charToJSString :: Char -> String
charToJSString char = case char of '\r' -> "\\r"
                                   '\n' -> "\\n"
                                   '\0' -> "\\0"
                                   '\\' -> "\\"
                                   '\'' -> "\\'"
                                   '\"' -> "\\\""
                                   '\v' -> "\\v"
                                   '\t' -> "\\t"
                                   '\b' -> "\\b"
                                   '\f' -> "\\f"
                                   char -> [char]

getEditTextFile :: String -> ActionM ()
getEditTextFile urlPath = do
        binaryData <- liftIO $ D.readFile $ rootPath <> urlPath
        let content = DT.unpack $ DTE.decodeUtf8With lenientDecode binaryData

        {- there are two line breaks, one is character '\r' in file, another is "\r" in string -}

        {- "/text/a.bc: JSString \"test\\r\\nabc\\r\\n\"" -}
        {- concatMap (\x -> if x == '\r' then "\\r" else [x]) "a\r\nb" == "a\\r\nb" -}
        {- there're 13 case, https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String#escape_sequences -}

        {- let jsString = show $ textToStr $ DTE.decodeUtf8With lenientDecode binaryData -}
        let jsString = concatMap charToJSString content

        liftIO $ print $ urlPath <> ": " <> jsString

        addHeader "Content-Type" "text/html; charset=utf-8"
        let fileName = DTL.unpack $ DL.last $ DTL.splitOn "/" $ DTL.pack urlPath
        let h0 = "<html lang=\"zh-CN\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">  <title>" <> fileName <> "</title>\n </head>\n <body>\n"
        let h1 = "<a href=\"/\">home</a><br><br>"
        let h2 = "<form id='editForm' enctype=\"multipart/form-data\" action=\"" <> urlPath <> "\" method=\"post\">"
        let h2_ = "<input type=\"hidden\" name=\"mode\" value=\"write\">"
        let h3 = "<textarea id=\"formData\" rows=\"6\" cols=\"36\" name=\"" <> urlPath <> "\"></textarea> <br> <input onclick=\"clearForm()\" type=\"submit\" value=\"Submit\"> </form> <br>"
        let h4 = "<script> document.addEventListener('DOMContentLoaded', (event) => {document.getElementById('formData').value = '" <> jsString <> "'});function clearForm() { var fm = document.getElementById('editForm')[0]; fm.submit();fm.reset(); document.getElementById('formData').value = '';};  </script>"
        {- let h4 = "<script> document.getElementById('formData').value = \"abc\";function clearForm() { var fm = document.getElementById('myForm')[0]; fm.submit(); fm.reset();}; if (window.history.replaceState) {windows.history.replaceState(null, null, window.location.href)} </script>" -}
        liftIO $ print h4
        let h5 = "</body>\n </html>\n" 
        html $ DTL.pack $ h0 <> h1 <> h2 <> h2_ <> h3 <> h4 <> h5

routePatternToUrlPath :: String -> ActionM String
routePatternToUrlPath routePattern = do
    urlPathList <- traverse param $ DL.filter (/= "") $ DTL.splitOn "/:" $ DTL.pack routePattern
    let urlPath = concat $ fmap ("/" <>) urlPathList
    return urlPath

{- passing two continuations into one ContT is hard -}
{- runContT (getFileOrDirectory "/a/b" getChunkedFile) generateHtmlForDirectory -}
getFileOrDirectory :: String -> (String -> ActionM ()) -> ContT () ActionM String
getFileOrDirectory urlPath fileAction = ContT $ \directoryAction -> do
    if urlPath `notElem` doNotShowPath then liftIO $ print $ "get " <> urlPath
    else return ()
    -- limit the access
    let urlPathList = DL.filter (/= "") $ DTL.splitOn "/" $ DTL.pack urlPath
    if "/" <> (head urlPathList) `notElem` accessPoint then text "not found"
    else do
        isExist <- liftIO $ fileExist $ rootPath <> urlPath
        if isExist then do
            fileStatus <- liftIO $ getFileStatus $ rootPath <> urlPath
            if isDirectory fileStatus then directoryAction urlPath
            else fileAction urlPath
        else text "not found"

generateHomePageHtml :: String -> ActionM ()
generateHomePageHtml rootPath = do
    addHeader "Content-Type" "text/html; charset=utf-8"
    liftIO $ print "get /"
    let h0 = "<html lang=\"en-US\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> <title> index </title>\n </head>\n <body>\n"
    let h1 = foldl1 (<>) (fmap (\x -> "<a href=\"" <> x  <> "\"> " <> x <> "</a> <br> <br> <br>" <> "\n") ["/paste", "/docs", "/config", "/code", "/upload", "/text", "/audio", "/video", "/picture", "/others", "/chunk"])
    html $ h0 <> h1

{- there are request and response, and web server only can do response to client's request, except redirect -}
{- and then you can use param in url with redirect -}
checkLogin url = authCheck $ redirect $ "/login?from=" <> url

main :: IO ()
main = do
    initializeCookieDb sessionConfig
    scottyTLS 3000 "server.key" "server.crt" $ do
        get "/" $ checkLogin "/" $ generateHomePageHtml rootPath
        get "/video" $ checkLogin "/video" $ generateVideoHtml "/video"
        get "/text" $ checkLogin "/text" $ generateTextHtml "/text"
        get "/paste" $ checkLogin "/paste" $ generatePasteHtml "/paste"
        get "/denied" $ text "access denied"
        get "/login" $ (authCheck $ do 
            addHeader "Content-Type" "text/html; charset=utf-8"
            (from :: String) <- param "from"
            liftIO $ print $ "from " <> from
            html $ DTL.pack $ unlines $
                            [ "<form method=\"POST\" action=\"/login\">"
                            , "<label for=\"username\">User:</label> <input type=\"text\" name=\"username\"> <br> <br>"
                            , "<label for=\"password\">Pass:</label> <input type=\"password\" name=\"password\"> <br> <br>"
                            , "<input type=\"hidden\" name=\"from\" value=\"" <> from <> "\">"
                            , "<input type=\"submit\" name=\"login\" value=\"login\">"
                            , "</form>" ]
            ) $ redirect "/"
    
        get "/test" $ do 
            addHeader "Content-Type" "text/html; charset=utf-8"
            liftIO $ print "get /test"
            agent <- header "User-Agent"
            liftIO $ print agent
            setSimpleCookie "this-is-cookie-name" "b"
            text "hi"

        {- get first level  -}
        traverse (\path -> get (capture path) $ checkLogin (DTL.pack path) $ generateFilePondHtml path) ["/upload", "/audio", "/picture", "/others", "/chunk"]

        {- get arbitrary level under /text -}
        traverse (\routePattern -> get (capture $ "/text" <> routePattern) $ do
            _urlPath <- routePatternToUrlPath routePattern
            let urlPath = "/text" <> _urlPath
            checkLogin (DTL.pack urlPath) $ runContT (getFileOrDirectory urlPath getTextFile) generateHtmlForDirectory) routePatternList

        {- get arbitrary level -}
        traverse (\routePattern -> get (capture routePattern) $ do
            urlPath <- routePatternToUrlPath routePattern
            checkLogin (DTL.pack urlPath) $ runContT (getFileOrDirectory urlPath getChunkedFile) generateHtmlForDirectory) routePatternList
    
        post "/login" $ do
            liftIO $ print $ "post /login"
            (from :: String) <- param "from"
            liftIO $ print $ "from " <> from
            (usn :: String) <- param "username"
            (pass :: String) <- param "password"
            if usn == "user" && pass == "pass"
                then do 
                    id <- addSession sessionConfig
                    liftIO $ print id
                    {- redirect "/" -}
                    redirect $ DTL.pack from
                else text "invalid user or wrong password"

        post "/paste" $ checkLogin "/paste" $ do
            binaryData <- param "/paste"
            let strData = BSC.unpack binaryData
            liftIO $ print $ "post /paste with " <> strData
            if BSC.null binaryData then liftIO $ print "empty submit"
            else liftIO $ insertFileWithByteString (rootPath <> "/paste/paste.txt") $ binaryData <> (BSC.pack "\r\n\r\n")
            generatePasteHtml "/paste"

        post "/video" $ authCheck (redirect "/login") $ do
            binaryData <- param "/video"
            let strData = BSC.unpack binaryData
            liftIO $ print $ "post /video with " <> strData
            if BSC.null binaryData then liftIO $ print "empty submit"
            else do
                _d <- liftIO $ getCurrentTime
                let _t = addUTCTime (60*60*8 :: NominalDiffTime) _d
                let _date = fmap (\x -> if x == ' ' then '.' else x) $ DL.take 19 $ show _t
                {- apt install ffmpeg, to fix malformed AAC bitstream for youtube-dl -}
                liftIO $ callCommand ("cd video; youtube-dl --no-mtime -o '" <> _date <> ".%(ext)s' " <> strData)
            generateVideoHtml "/video"

        post "/text" $ authCheck (redirect "/login") $ runContT (postChunkedDataFromFilePond "/text") generateTextHtml

        post "/text/create" $ authCheck (redirect "/login") $ do
            binaryData <- param "newFile"
            if BSC.null binaryData then liftIO $ print "emtype fileName"
            else do
                let strData = BSC.unpack binaryData
                let filePath = rootPath <> "/text/" <> strData
                if (DL.last strData) == '/' then liftIO $ createDirectoryIfMissing True filePath
                else do
                    isExist <- liftIO $ fileExist $ filePath
                    if isExist then text "file existed!"
                    else liftIO $ D.writeFile filePath ""
            redirect "/text"

        {- post arbitrary level under /text -}
        traverse (\routePattern -> post (capture $ "/text" <> routePattern) $ do
            _urlPath <- routePatternToUrlPath routePattern
            let urlPath = "/text" <> _urlPath
            checkLogin (DTL.pack urlPath) $ do
                binaryData <- param (DTL.pack urlPath)
                (fileMode :: String) <- param "mode"
                liftIO $ print $ "mode " <> fileMode
                let strData = BSC.unpack binaryData
                liftIO $ print $ "post " <> urlPath <> " with " <> strData
                if BSC.null binaryData then liftIO $ print "empty submit"
                else if strData == "edit" then do
                    getEditTextFile urlPath
                    {- liftIO $ writeFile (rootPath <> urlPath) "" -}
                else if fileMode == "append" then do 
                    liftIO $ insertFileWithByteString (rootPath <> urlPath) $ binaryData <> (BSC.pack "\r\n")
                    getTextFile urlPath
                else do
                    liftIO $ writeFile (rootPath <> urlPath) ""
                    liftIO $ D.writeFile (rootPath <> urlPath) binaryData
                    getTextFile urlPath
                return ()
            ) routePatternList

        {- post first level -}
        traverse (\path -> post (capture path) $ authCheck (redirect "/login") $ runContT (postChunkedDataFromFilePond path) generateFilePondHtml) ["/upload", "/audio", "/picture", "/others", "/chunk"]

        return ()
