postChunkedDataFromFilePond :: (String -> ActionM ()) -> String -> ActionM ()
postChunkedDataFromFilePond afterPostGenerateHtml pathName = do
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

{- getFileOrDirectory getChunkedFile generateHtmlForDirectory "/a/b" -}
getFileOrDirectory :: (String -> ActionM ()) -> (String -> ActionM ()) -> String -> ActionM ()
getFileOrDirectory fileAction directoryAction urlPath = do
    if urlPath `notElem` doNotShowPath then liftIO $ print $ "get " <> urlPath
    else return ()
    -- limit the access
    let urlPathList = DL.filter (/= "") $ DTL.splitOn "/" $ DTL.pack urlPath
    if "/" <> (head urlPathList) `notElem` accessPoint then text "not found"
    else do
        {- let filePath = rootPath <> urlPath -}
        {- isExist <- liftIO $ fileExist filePath -}
        isExist <- liftIO $ fileExist $ rootPath <> urlPath
        if isExist then do
            fileStatus <- liftIO $ getFileStatus $ rootPath <> urlPath
            {- if isDirectory fileStatus then directoryAction filePath -}
            if isDirectory fileStatus then directoryAction urlPath
            else fileAction $ rootPath <> urlPath
        else text "not found"

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
        {- let filePath = rootPath <> urlPath -}
        {- isExist <- liftIO $ fileExist filePath -}
        isExist <- liftIO $ fileExist $ rootPath <> urlPath
        if isExist then do
            fileStatus <- liftIO $ getFileStatus $ rootPath <> urlPath
            {- if isDirectory fileStatus then directoryAction filePath -}
            if isDirectory fileStatus then directoryAction urlPath
            else fileAction $ rootPath <> urlPath
        else text "not found"

