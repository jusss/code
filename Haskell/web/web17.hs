{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
import Network.Wai
import Network.Wai.Parse hiding (parseContentType)
import Network.Multipart
import Network.HTTP.Types hiding (urlEncode)
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
import qualified Data.Map.Internal as DMI
import Data.Char
import Data.String.Split (splitOn)
import Data.Binary.Builder
import Data.Text.Lazy.Encoding
import qualified Data.Text.Encoding as DTE
import Data.Text.Encoding.Error
import Data.Time.Clock
import Data.Time.Clock.POSIX
import Data.UUID.V4
import qualified Data.UUID as DU
import qualified System.Posix.IO as SPI
import qualified Data.List as DL
import qualified Data.List.Split as DLS
import qualified Data.Text as DT
import qualified Data.Text.IO as DTI
import qualified Data.Text.Lazy as DTL
import qualified Data.ByteString as D
import qualified Data.ByteString.Lazy as DB
import qualified Data.ByteString.Lazy.UTF8 as DBLU
import qualified Data.ByteString.Char8 as BSC
import qualified Data.ByteString.Lazy.Char8 as DBL
import Network.Wai.Middleware.Gzip (gzip, def, gzipFiles, GzipFiles(GzipCompress))
import Network.HTTP.Base (urlEncode)
import qualified Network.Wreq as NW
import Control.Lens (view, (^.))
import Text.HTML.TagSoup
import Text.HTML.TagSoup.Match

{- no more html file, just html strings for directory -}
{- there're urlPath like /a/b and filePath like rootPath <> urlPath -}
rootPath = "/root/web"
accessPoint = ["/paste", "/docs", "/config", "/code", "/upload", "/text", "/audio", "/video", "/picture", "/others", "/chunk", "/node_modules"]
routePatternList = scanl1 (<>) $ fmap (("/:" <>) . ("l" <>) . show) [1..99]
{- do not show visit path on console -}
doNotShowPath = ["/favicon.ico", "/node_modules/filepond/dist/filepond.css", "/node_modules/filepond/dist/filepond.js"]

{- encode /a/b/c for non-ascii characters -}
urlPathEncode urlPath = DL.foldl1 (\x -> \y -> x <> "/" <> y) $ fmap urlEncode $ DLS.splitOn "/" urlPath

{- in order to show text with utf8 in get request,  -}
{- addHeader "Content-Type" "text/plain; charset=utf-8", for file -}
{- addHeader "Content-Type" "text/html; charset=utf-8", for directory html string -}

-- the defaultSessionConfig is 120 sec to expire, change it to 6 day
sessionConfig :: SessionConfig
sessionConfig = SessionConfig "sessions.sqlite3" 1200 600000 False

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

listFileHtml pathName fileList = 
    if null fileList then "" else foldl1 (<>) (fmap (\x -> "<a href=\"" <> (urlPathEncode $ pathName <> "/" <> x) <> "\"> " <> x <> "</a> <br>" <> "\n") fileList)

titleHtml pathName = "<html lang=\"zh-CN\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">  <title>" <> pathName <> "</title>\n </head>\n <body>\n"

titleWithFilePondHtml pathName = "<html lang=\"en-US\">\n <head>\n <meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"> <title>" <> pathName <> "</title>\n <link href=\"/node_modules/filepond/dist/filepond.css\" rel=\"stylesheet\" />\n <script src=\"/node_modules/filepond/dist/filepond.js\"></script>\n </head>\n <body>\n"

homeHtml = "<a href=\"/\">home</a><br><br>"

getTitleFromLink :: String -> IO String
getTitleFromLink url = do
    if DL.isPrefixOf "http" url then do
        result  <- try (NW.get url) :: IO (Either SomeException (NW.Response DB.ByteString))
        case result of
            Left ex -> do
                return $ url <> "\r\n"
            Right r -> do
                let doc = parseTags $ DBL.unpack $ r ^. NW.responseBody
                let (a,b) = DL.break (\x -> x == TagOpen "title" []) doc
                if DL.null b then
                    return $ url <> "\r\n"
                else
                    return $ (fromTagText $ head $ drop 1 $ take 2 b) <> "\r\n" <> url <> "\r\n\r\n"
    else
        return $ url <> "\r\n"


generateVideoHtml :: String -> ActionM ()
generateVideoHtml pathName = do
        addHeader "Content-Type" "text/html; charset=utf-8"
        liftIO $ print $ "get " <> pathName
        liftIO $ createDirectoryIfMissing True $ rootPath <> pathName
        fileList <- liftIO $ listDirectoryAscendingByTime $ rootPath <> pathName
        let h0 = titleHtml pathName
        let h1 = homeHtml
        let h2 = "<form id='myForm' enctype=\"multipart/form-data\" action=\"" <> pathName <> "\" method=\"post\">"
        let h3 = "<textarea id=\"formData\" rows=\"6\" cols=\"36\" name=\"" <> pathName <> "\"></textarea> <br> <input onclick=\"clearForm()\" type=\"submit\" value=\"Submit\"> </form> <br>"
        let h4 = listFileHtml pathName fileList
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
        let h0 = titleHtml pathName
        let h1 = homeHtml
        let h2 = "<form id='myForm' enctype=\"multipart/form-data\" action=\"" <> pathName <> "\" method=\"post\">"
        let h3 = "<textarea id=\"formData\" rows=\"6\" cols=\"36\" name=\"" <> pathName <> "\"></textarea> <br> <input onclick=\"clearForm()\" type=\"submit\" value=\"Submit\"> </form> <br>"
        let h4 = "<script> function clearForm() { var fm = document.getElementById('myForm')[0]; fm.submit(); fm.reset(); document.getElementById('formData').value = '';}; if (window.history.replaceState) {windows.history.replaceState(null, null, window.location.href)} </script>"
        binaryData <- liftIO $ D.readFile $ rootPath <> pathName <> "/paste.txt"


        let h5 = concat $ fmap (\x -> if DL.isPrefixOf "http" x then "<a href=\"" <> x <> "\" target=\"_blank\" rel=\"noopener noreferrer\">" <> x <> "</a><br>" else x <> "<br>") $ lines $ DT.unpack $ DTE.decodeUtf8With lenientDecode binaryData



        let h6 = "</body>\n </html>\n" 
        html $ DTL.pack $ h0 <> h1 <> h2 <> h3 <> h4 <> h5 <> h6

generatePictureHtml :: String -> ActionM ()
generatePictureHtml pathName = do
        {- pics in picture/ and thumbs in picture/.thumb/ -}
        {- apt install imagemagick; mkdir picture/.thumb -}
        {- for i in *.jpg; do convert -thumbnail 360 $i .thumb/$i; done; -}
        {- addHeader "Content-Type" "text/html; charset=utf-8" -}
        liftIO $ print $ "get " <> pathName
        liftIO $ createDirectoryIfMissing True $ rootPath <> pathName
        _fileList <- liftIO $ listDirectoryAscendingByTime $ rootPath <> pathName
        let fileList = DL.filter (\x -> not $ "." `DL.isPrefixOf` x) _fileList
        liftIO $ createDirectoryIfMissing True $ rootPath <> pathName <> "/.thumb"
        _thumbFileList <- liftIO $ listDirectoryAscendingByTime $ rootPath <> pathName <> "/.thumb"
        let thumbFileList = DL.filter (\x -> not $ "." `DL.isPrefixOf` x) _thumbFileList
        let missingThumb = fileList DL.\\ thumbFileList
        if null missingThumb then liftIO $ print "all thumbnail generated" else liftIO $ callCommand ("cd picture; for i in " <> (foldl1 (\x -> \y -> x <> " " <> y) missingThumb) <> "; do convert -thumbnail 112x112 $i .thumb/$i; done;")

        let original_pic_list = DL.filter (\x -> not $ "." `DL.isPrefixOf` x) fileList
        let h0 = titleWithFilePondHtml pathName
        let h1 = homeHtml
        let h2 = "<input type=\"file\" multiple><br><br><br>\n" 
        let h3 = "<style> .wrapper {display: grid; grid-template-columns: repeat(auto-fit, minmax(112px, 1fr)); gap:1px;} @media (max-width: 768px) { .wrapper {grid-template-columns: repeat(3, 1fr);}} </style>"
        let h4 = "<div class=\"wrapper\">"
        let h5 = if null fileList then "" else foldl1 (<>) (fmap (\x -> "<div><a href=\"" <> pathName <> "/" <> x <> "\"><img src=\"" <> pathName <> "/.thumb/" <> x <> "\">" <> "</a></div>" <> "\n") original_pic_list)
        let h6 = "</div></body>\n <script> const inputElement = document.querySelector('input[type=\"file\"]'); const pond = FilePond.create( inputElement ); pond.setOptions({ server: \"" <> pathName <> "\" }) </script> </html>\n" 
        html $ DTL.pack $ h0 <> h1 <> h2 <> h3 <> h4 <> h5 <> h6

generateUploadWithChunkHtml :: String -> ActionM ()
generateUploadWithChunkHtml pathName = do
        {- addHeader "Content-Type" "text/html; charset=utf-8" -}
        addHeader "Transfer-Encoding" "chunked"
        liftIO $ print $ "get " <> pathName
        fileList <- liftIO $ listDirectoryAscendingByTime $ rootPath <> pathName
        liftIO $ createDirectoryIfMissing True $ rootPath <> pathName
        {- multipart/form-data will make webKitFormBoundary in body, multiple files post only once with chunked, multiple IO String read -}
        let h1 = titleHtml pathName
        let h2 = homeHtml
        let h3 = "<form enctype=\"multipart/form-data\" action=\"" <> pathName <> "\" method=\"post\">"
        let h4 = "<input type=\"file\" name=\"" <> pathName <> "\" multiple=\"multiple\"><input type=\"submit\" value=\"Submit\"></form>"
        let h5 = listFileHtml pathName fileList
        let h6 = "</body></html>"
        (html .DTL.pack) $ h1 <> h2 <> h3 <> h4 <> h5 <> h6

generateFilePondHtml :: String -> ActionM ()
generateFilePondHtml pathName = do
        {- addHeader "Content-Type" "text/html; charset=utf-8" -}
        liftIO $ print $ "get " <> pathName
        fileList <- liftIO $ listDirectoryAscendingByTime $ rootPath <> pathName
        liftIO $ createDirectoryIfMissing True $ rootPath <> pathName
        let h0 = titleWithFilePondHtml pathName
        let h1 = homeHtml
        let h2 = "<input type=\"file\" multiple><br><br><br>\n" 
        let h3 = listFileHtml pathName fileList
        let h4 = "</body>\n <script> const inputElement = document.querySelector('input[type=\"file\"]'); const pond = FilePond.create( inputElement ); pond.setOptions({ server: \"" <> pathName <> "\" }) </script> </html>\n" 
        html $ DTL.pack $ h0 <> h1 <> h2 <> h3 <> h4

generateTextHtmlWithFilePond :: String -> ActionM ()
generateTextHtmlWithFilePond urlPath = do
        {- addHeader "Content-Type" "text/html; charset=utf-8" -}
        liftIO $ print $ "get " <> urlPath
        fileList <- liftIO $ listDirectoryAscendingByTime $ rootPath <> urlPath
        liftIO $ createDirectoryIfMissing True $ rootPath <> urlPath
        let h0 = titleWithFilePondHtml urlPath
        let h1 = homeHtml
        let hf = "<form action=\"" <> urlPath <> "/create" <> "\"  method=\"post\"> <label for=\"fileName\">New File:</label> <input type=\"text\" name=\"newFile\" value=\"\"><input type=\"submit\" value=\"Create\"></form>"
        let h2 = "<input type=\"file\" multiple><br><br><br><br><br><br>\n" 
        {- let h3 = if null fileList then "" else foldl1 (<>) (fmap (\x -> "<a href=\"" <> urlPath <> "/" <> x <> "\"> " <> x <> "</a> <br><br>" <> "\n") fileList) -}
        let h3 = listFileHtml urlPath fileList
        let h4 = "</body>\n <script> const inputElement = document.querySelector('input[type=\"file\"]'); const pond = FilePond.create( inputElement ); pond.setOptions({ server: \"" <> urlPath <> "\" }) </script> </html>\n" 
        html $ DTL.pack $ h0 <> h1 <> hf <> h2 <> h3 <> h4

getFileList :: String -> IO [String]
getFileList path = do
        _fileList <- listDirectoryAscendingByTime path
        _tf <- traverse doesDirectoryExist $ fmap ((path <> "/") <>) _fileList
        let regularFileList = fmap fst $ filter ((/= True) . snd) $ zip _fileList _tf
        let dirFileList = fmap (<> "/") $ fmap fst $ filter ((== True) . snd) $ zip _fileList _tf
        {- liftIO $ print dirFileList -}
        let fileList = dirFileList <> regularFileList
        {- liftIO $ print fileList -}
        return fileList

generateTextHtml :: String -> ActionM ()
generateTextHtml urlPath = do
        {- addHeader "Content-Type" "text/html; charset=utf-8" -}
        liftIO $ print $ "get " <> urlPath
        fileList <- liftIO $ getFileList $ rootPath <> urlPath
        liftIO $ createDirectoryIfMissing True $ rootPath <> urlPath
        let urlDirectory = if (length $ DL.filter (/= "") $ splitOn "/" urlPath) == 1 then "/" else concat $ fmap ("/" <> ) $ DL.init $ DL.filter (/= "") $ splitOn "/" urlPath
        let h0 = titleHtml urlPath
        let h1 = "<a href=\"/\">home</a> &nbsp &nbsp &nbsp "
        let hb = "<a href=\"" <> urlDirectory <> "\">back</a><br><br>"
        let hf = "<form action=\"" <> urlPath <> "?fileMode=create" <> "\"  method=\"post\"> <label for=\"fileName\">New File:</label> <input type=\"text\" name=\"data\" value=\"\"> <input type=\"submit\" value=\"Create\"></form>"

        let hf_ = "<form action=\"" <> urlPath <> "?fileMode=delete" <> "\"  method=\"post\"> <label for=\"fileName\">Delete File:</label> <input type=\"text\" name=\"data\" value=\"\"> <input type=\"submit\" value=\"Delete\"></form>"

        let hf__ = "<form action=\"" <> urlPath <> "?fileMode=download" <> "\"  method=\"post\"> <label for=\"fileName\">Download File:</label> <input type=\"text\" name=\"data\" value=\"\"> <input type=\"submit\" value=\"Download\"></form>"

        let h2 = "<form enctype=\"multipart/form-data\" action=\"" <> urlPath <> "?fileMode=upload" <> "\" method=\"post\"><input type=\"file\" name=\"" <> urlPath <> "\" multiple> <input type=\"submit\" value=\"Upload\"> </form> <br>"
        {- let h3 = if null fileList then "" else foldl1 (<>) (fmap (\x -> "<a href=\"" <> urlPath <> "/" <> x <> "\"> " <> x <> "</a> <br> <br>" <> "\n") fileList) -}

        let h3 = listFileHtml urlPath fileList
        let h4 = "</body></html>" 
        html $ DTL.pack $ h0 <> h1 <> hb <> hf <> hf_ <> hf__ <> h2 <> h3 <> h4

postFiles :: String -> ActionM ()
postFiles urlPath = do
    _files <- files
    {- traverse (\_file -> liftIO $ DB.writeFile (rootPath <> (DTL.unpack $ fst _file) <> "/" <> (BSC.unpack $ fileName $ snd _file)) (fileContent $ snd _file)) _files -}
    traverse (\_file -> do
        let uploadUrlPath = DTL.unpack $ fst _file
        let uploadFileName = BSC.unpack $ fileName $ snd _file
        if uploadFileName == "\"\"" then 
            {- finish -}
            liftIO $ print "upload empty file"
            {- early exit here -}
        else liftIO $ DB.writeFile (rootPath <> uploadUrlPath <> "/" <> uploadFileName) (fileContent $ snd _file)
        ) _files
    redirect $ DTL.pack urlPath

{- strict upload and lazy parse -}
readFromBodyPartWriteFile :: String -> BodyPart -> IO ()
readFromBodyPartWriteFile pathName (BodyPart headers bytestring) = do
    let _filename = DL.init $ DL.tail $ DTL.unpack $ DL.last $ DTL.splitOn "filename=" $ DTL.pack $ (DMI.fromList headers) DMI.! (HeaderName "Content-Disposition")
    let filename = rootPath <> pathName <> "/" <> _filename
    print $ "post file " <> filename
    DB.writeFile filename DB.empty
    DB.appendFile filename bytestring

readAndWrite :: IO D.ByteString -> String -> String -> String -> IO ()
readAndWrite readSource filename bm pathName = do
        chunk <- readSource
        D.appendFile filename chunk
        let size = D.length chunk
        if size > 0 then do
            readAndWrite readSource filename bm pathName
        else do
            _all <- DB.readFile filename
            let MultiPart msg = parseMultipartBody bm _all
            traverse (readFromBodyPartWriteFile pathName) msg
            return ()

postChunkedData :: String -> ContT () ActionM String
postChunkedData pathName = ContT $ \afterPostGenerateHtml -> do
        ct <- header "Content-Type"
        ct_ <- liftIO $ parseContentType $ DTL.unpack $ fromJust ct
        let bm = (DMI.fromList $ ctParameters ct_) DMI.! "boundary"
        rd <- bodyReader
        uuid <- liftIO nextRandom
        let filename = DU.toString uuid
        liftIO $ readAndWrite rd filename bm pathName
        liftIO $ removeFile filename
        liftIO $ print $ "post " <> pathName
        afterPostGenerateHtml pathName

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
        {- let lastLevel = last $ splitOn "/" pathName -}
        {- fileList <- liftIO $ listDirectory $ rootPath <> pathName -}

        fileList <- liftIO $ getFileList $ rootPath <> pathName

        let h0 = titleHtml pathName
        let h1 = homeHtml
        let h2 = listFileHtml pathName fileList
        let h3 = "</body>\n </html>\n" 
        html $ DTL.pack $ h0 <> h1 <> h2 <> h3

{- since iOS won't preview mp4 file, so comment it for just download -}
headerContentTypeForiOS = DMI.fromList [("jpg", "image/jpeg"), ("jpeg", "image/jpeg"), ("png", "image/png"),
                        ("pdf", "application/pdf"),
                        ("txt", "text/plain; charset=utf-8")]

-- headerContentType = DMI.fromList [("jpg", "image/jpeg"), ("jpeg", "image/jpeg"), ("png", "image/png"),
                        -- ("mp4", "video/mp4"), ("m4a", "video/mp4"), ("mkv", "video/x-matroska"),
                        -- ("webm", "video/webm"), ("mov", "video/quicktime"), ("avi", "video/x-msvideo"),
                        -- ("aac", "audio/aac"), ("ogg", "audio/ogg"), ("wav", "audio/wav"),
                        -- ("pdf", "application/pdf"),
                        -- ("txt", "text/plain; charset=utf-8")]

headerContentType = DMI.fromList [("jpg", "image/jpeg"), ("jpeg", "image/jpeg"), ("png", "image/png"),
                        -- ("mp4", "video/mp4"), ("m4a", "video/mp4"), ("mkv", "video/x-matroska"),
                        ("webm", "video/webm"), ("mov", "video/quicktime"), ("avi", "video/x-msvideo"),
                        ("aac", "audio/aac"), ("ogg", "audio/ogg"), ("wav", "audio/wav"),
                        ("pdf", "application/pdf"),
                        ("txt", "text/plain; charset=utf-8")]

getChunkedFile :: String -> ActionM ()
getChunkedFile urlPath = do
        let fileSuffix = fmap toLower $ DL.last $ splitOn "." $ DL.last $ splitOn "/" urlPath

        userAgent <- header "User-Agent"
        {- liftIO $ print userAgent -}

        case userAgent of
            Just x -> case "Mac OS X" `DTL.isInfixOf` x of
                        True -> case DMI.lookup fileSuffix headerContentTypeForiOS of
                                    Just x -> (addHeader "Content-Type" x) >> (addHeader "Content-Disposition" "inline")
                                    Nothing -> addHeader "Content-Disposition" "attachment"
                        False -> case DMI.lookup fileSuffix headerContentType of
                                    Just x -> (addHeader "Content-Type" x) >> (addHeader "Content-Disposition" "inline")
                                    Nothing -> addHeader "Content-Disposition" "attachment"
            Nothing -> addHeader "Content-Disposition" "attachment"

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

backUrlPath :: String -> String
backUrlPath urlPath = if (length $ DL.filter (/= "") $ splitOn "/" urlPath) == 1 then "/" else concat $ fmap ("/" <> ) $ DL.init $ DL.filter (/= "") $ splitOn "/" urlPath

getTextFile :: String -> ActionM ()
getTextFile urlPath = do
        addHeader "Content-Type" "text/html; charset=utf-8"
        {- timestamp for preventing iframe cache -}
        _timestamp <- liftIO $ getPOSIXTime
        let timestamp = show _timestamp
        let urlPathWithWriteParam = urlPath <> "?fileMode=write&timestamp=" <> timestamp
        let urlPathWithAppendParam = urlPath <> "?fileMode=append&timestamp=" <> timestamp
        let urlPathWithReadParam = urlPath <> "?contentType=plain&fileMode=read&timestamp=" <> timestamp
        let urlDirectory = backUrlPath urlPath
        let fileName = DL.last $ splitOn "/" urlPath
        let h0 = titleHtml fileName
        let h1 = "<a href=\"/\">home</a> &nbsp &nbsp &nbsp"
        let hb = "<a href=\"" <> urlDirectory <> "\">back</a> &nbsp &nbsp &nbsp"
        let hf = "<a href=\"" <> urlPathWithWriteParam <> "\">edit</a> &nbsp &nbsp &nbsp"
        let hf_ = "<a href=\"" <> urlPath <> "?fileMode=download" <> "\">download</a> &nbsp &nbsp &nbsp" 
        let hp = "<a href=\"" <> urlPath <> "?fileMode=delete" <> "\" onclick=\"return confirm('Are you sure you want to delete it?');\">delete</a><br><br>"
        let h2 = "<form id='myForm' enctype=\"multipart/form-data\" action=\"" <> urlPathWithAppendParam <> "\" method=\"post\">"
        let h3 = "<textarea style=\"width: 100%; height: 16%;\" id=\"formData\" name=\"data\"></textarea> <br> <input onclick=\"clearForm()\" type=\"submit\" value=\"Submit\"> </form> <br>"

        {- let h4 = "<iframe src=\"" <> urlPathWithReadParam <> "\"  width=\"100%\" height=\"100%\"   ></iframe>" -}
        let h4 = "<div id=\"content\"></div>"

        {- reading html text file with Hasekll and put it into textarea with js is a wrong way, lots of escape characters, the right way is using js to fetch the content of that text file as plain text and put it into textarea -}

        if DL.isSuffixOf ".http" fileName then do
            binaryData <- liftIO $ D.readFile $ rootPath <> urlPath
            let d = concat $ fmap (\x -> if DL.isPrefixOf "http" x then "<a href=\\\"" <> x <> "\\\" target=\\\"_blank\\\" rel=\\\"noopener noreferrer\\\">" <> x <> "</a><br>" else x <> "<br>") $ lines $ DT.unpack $ DTE.decodeUtf8With lenientDecode binaryData
            liftIO $ print d
            let d2 = DL.filter (\x -> x /= '\n') $ DL.filter (\x -> x /= '\r') d

            let h5 = "<script> {document.getElementById('content').innerHTML = \"" <> d2 <> "\"};function clearForm() { var fm = document.getElementById('myForm')[0]; fm.submit(); fm.reset(); document.getElementById('formData').value = '';}; if (window.history.replaceState) {windows.history.replaceState(null, null, window.location.href)} </script>"

            let h6 = "</body>\n </html>\n" 
            html $ DTL.pack $ h0 <> h1 <> hb <> hf <> hf_ <> hp <> h2 <> h3 <> h4 <> h5 <> h6

        else do
            let h5 = "<script> fetch(\"" <> urlPathWithReadParam <> "\").then((r)=>{r.text().then((d)=>{  document.getElementById('content').innerText = d })});function clearForm() { var fm = document.getElementById('myForm')[0]; fm.submit(); fm.reset(); document.getElementById('formData').value = '';}; if (window.history.replaceState) {windows.history.replaceState(null, null, window.location.href)} </script>"
            let h6 = "</body>\n </html>\n" 
            html $ DTL.pack $ h0 <> h1 <> hb <> hf <> hf_ <> hp <> h2 <> h3 <> h4 <> h5 <> h6

        -- let h6 = "</body>\n </html>\n" 
        -- html $ DTL.pack $ h0 <> h1 <> hb <> hf <> hf_ <> hp <> h2 <> h3 <> h4 <> h5 <> h6

getEditTextFile :: String -> ActionM ()
getEditTextFile urlPath = do
        _timestamp <- liftIO $ getPOSIXTime
        let timestamp = show _timestamp
        let urlPathWithReadParam = urlPath <> "?contentType=plain&fileMode=read&timestamp=" <> timestamp
        let urlDirectory = backUrlPath urlPath
        addHeader "Content-Type" "text/html; charset=utf-8"
        let fileName = DL.last $ splitOn "/" urlPath
        let h0 = titleHtml fileName
        let h1 = "<a href=\"/\">home</a> &nbsp &nbsp &nbsp"
        {- let hb = "<a href=\"" <> urlDirectory <> "\">back</a><br><br>" -}
        let hb = "<a href=\"" <> urlPath <> "\">back</a><br><br>"
        let h2 = "<form id='editForm' enctype=\"multipart/form-data\" action=\"" <> urlPath <> "?fileMode=write" <> "\" method=\"post\">"
        let h3 = "<textarea style=\"width: 100%; height: 90%;\"  id=\"formData\" name=\"data\"></textarea> <br> <input onclick=\"clearForm()\" type=\"submit\" value=\"Submit\"> </form> <br>"
        let h4 = "<script> fetch(\"" <> urlPathWithReadParam <> "\").then((r)=>{r.text().then((d)=>{  document.getElementById('formData').value = d })}); function clearForm() { var fm = document.getElementById('myForm')[0]; fm.submit(); fm.reset(); document.getElementById('formData').value = '';}; if (window.history.replaceState) {windows.history.replaceState(null, null, window.location.href)} </script>"
        let h5 = "</body>\n </html>\n" 
        html $ DTL.pack $ h0 <> h1 <> hb <> h2 <> h3 <> h4 <> h5

routePatternToUrlPath :: String -> ActionM String
routePatternToUrlPath "" = return ""
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
        get "/paste" $ checkLogin "/paste" $ generatePasteHtml "/paste"
        get "/picture" $ checkLogin "/picture" $ generatePictureHtml "/picture"
        get "/denied" $ text "access denied"
        get "/login" $ (authCheck $ do 
            addHeader "Content-Type" "text/html; charset=utf-8"
            (from :: String) <- param "from"
            liftIO $ print $ "get " <> from <> " as logout"
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
        traverse (\path -> get (capture path) $ checkLogin (DTL.pack path) $ generateFilePondHtml path) ["/upload", "/audio", "/chunk"]
        traverse (\path -> get (capture path) $ checkLogin (DTL.pack path) $ generateUploadWithChunkHtml path) ["/others"]

        {- get arbitrary level under /text -}
        traverse (\routePattern -> get (capture $ "/text" <> routePattern) $ do
            _urlPath <- routePatternToUrlPath routePattern
            let urlPath = "/text" <> _urlPath
            checkLogin (DTL.pack urlPath) $ do
                (contentType :: String) <- rescue (param "contentType") $ \exception -> return "html"
                (fileMode :: String) <- rescue (param "fileMode") $ \exception -> return "read"
                case fileMode of
                    "write" -> getEditTextFile urlPath
                    "delete" -> (liftIO $ removeFile $ rootPath <> urlPath) >> (redirect $ DTL.pack $ backUrlPath urlPath)
                    "download" -> do
                        let fileName = DL.last $ splitOn "/" urlPath
                        let filePath = rootPath <> urlPath
                        addHeader "Content-Disposition" $ "attachment; filename=\"" <> (DTL.pack fileName) <> "\""
                        file filePath

                    x -> case contentType of
                            "html" -> runContT (getFileOrDirectory urlPath getTextFile) generateTextHtml
                            "plain" -> (addHeader "Content-Type" "text/plain; charset=utf-8") >> file (rootPath <> urlPath)
                            _ -> text "wrong contentType"

            ) ([""] <> routePatternList)

        {- get arbitrary level -}
        traverse (\routePattern -> get (capture routePattern) $ do
            urlPath <- routePatternToUrlPath routePattern
            checkLogin (DTL.pack urlPath) $ runContT (getFileOrDirectory urlPath getChunkedFile) generateHtmlForDirectory) routePatternList
    
        post "/login" $ do
            liftIO $ print $ "post /login"
            (from :: String) <- param "from"
            liftIO $ print $ "login from " <> from
            (user :: String) <- param "username"
            (pass :: String) <- param "password"
            liftIO $ print $ "login as user " <> user <> ", password is " <> pass
            _d <- liftIO $ getCurrentTime
            let _t = addUTCTime (60*60*8 :: NominalDiffTime) _d
            let _date = fmap (\x -> if x == ' ' then '.' else x) $ DL.take 19 $ show _t
            liftIO $ appendFile "user.login" (_date <> " " <> user <> " " <> pass <> "\r\n")
            if user == "user" && pass == "pass"
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
            else do
                let strDataList = lines strData
                traverse (\_strData -> do
                        titleUrl <- liftIO $ getTitleFromLink _strData
                        liftIO $ insertFileWithByteString (rootPath <> "/paste/paste.txt") $ BSC.pack titleUrl
                    ) (reverse strDataList)
                return ()
            generatePasteHtml "/paste"

        post "/video" $ checkLogin "/video" $ do
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

        post "/url" $ do
            url <- param "/url"
            let urlData = BSC.unpack url
            liftIO $ print urlData
            text "I got it"

        {- post text or files at arbitrary level under /text -}
        traverse (\routePattern -> post (capture $ "/text" <> routePattern) $ do
            _urlPath <- routePatternToUrlPath routePattern
            let urlPath = "/text" <> _urlPath
            checkLogin (DTL.pack urlPath) $ do
                (fileMode :: String) <- param "fileMode"
                binaryData <- rescue (param "data") $ \exception -> return ("placeholder" :: D.ByteString)
                liftIO $ print $ "post " <> urlPath <> " with " <> fileMode
                if BSC.null binaryData then liftIO $ print "empty submit"
                else 
                    case fileMode of
                        "upload" -> postFiles urlPath
                        "create" -> do
                            let fileName = BSC.unpack binaryData
                            let filePath = rootPath <> urlPath <> "/" <> fileName
                            if (DL.last fileName) == '/' then liftIO $ createDirectoryIfMissing True filePath
                            else do
                                isExist <- liftIO $ fileExist $ filePath
                                if isExist then text "file existed!"
                                else liftIO $ D.writeFile filePath ""

                        "edit" -> getEditTextFile urlPath
                        "append" -> do
                            if DL.isSuffixOf ".http" urlPath then do
                                liftIO $ print "end with .http" 
                                liftIO $ print urlPath
                                let strData = BSC.unpack binaryData
                                let strDataList = lines strData
                                traverse (\_strData -> do
                                        titleUrl <- liftIO $ getTitleFromLink _strData
                                        liftIO $ insertFileWithByteString (rootPath <> urlPath) $ BSC.pack titleUrl
                                    ) (reverse strDataList)
                                return ()
                                
                            else do
                                liftIO $ print "end not with .http" 
                                liftIO $ print urlPath
                                
                                liftIO $ insertFileWithByteString (rootPath <> urlPath) $ binaryData <> (BSC.pack "\r\n")
                        {- "write" -> (liftIO $ writeFile (rootPath <> urlPath) "") >> (liftIO $ D.writeFile (rootPath <> urlPath) binaryData) -}
                        "write" -> liftIO $ (writeFile (rootPath <> urlPath) "") >> (D.writeFile (rootPath <> urlPath) binaryData)
                        "delete" -> do
                            let fileName = BSC.unpack binaryData
                            let filePath = rootPath <> urlPath <> "/" <> fileName
                            if (DL.last fileName) == '/' then liftIO $ removeDirectoryRecursive filePath
                            else do
                                isExist <- liftIO $ fileExist $ filePath
                                if isExist then liftIO $ removeFile filePath
                                else text "file do not existed!"
                        "download" -> do
                            let fileName = BSC.unpack binaryData
                            let filePath = rootPath <> urlPath <> "/" <> fileName
                            if (DL.last fileName) == '/' then text "directory can not be downloaded"
                            else do
                                isExist <- liftIO $ fileExist $ filePath
                                if isExist then do
                                    addHeader "Content-Disposition" $ "attachment; filename=\"" <> (DTL.pack fileName) <> "\""
                                    file filePath
                                {- if isExist then liftIO $ redirect $ urlPath <> "/" <> fileName <> "?contentType=plain" -}
                                else text "file do not existed!"

                        {- "rename" -> do -}
                            {- let fileName = BSC.unpack binaryData -}
                            {- let filePath = rootPath <> urlPath <> "/" <> fileName -}
                            {- if (DL.last fileName) == '/' then liftIO $ renamePath filePath -}
                            {- else do -}
                                {- isExist <- liftIO $ fileExist $ filePath -}
                                {- if isExist then liftIO $ removeFile filePath -}
                                {- else text "file do not existed!" -}

                        x -> return ()
                redirect $ (DTL.pack urlPath)
            ) ([""] <> routePatternList)

        {- post first level -}
        traverse (\path -> post (capture path) $ checkLogin (DTL.pack path) $ runContT (postChunkedDataFromFilePond path) generateFilePondHtml) ["/upload", "/audio", "/picture", "/chunk"]
        traverse (\path -> post (capture path) $ checkLogin (DTL.pack path) $ runContT (postChunkedData path) generateUploadWithChunkHtml) [ "/others"]

        return ()
