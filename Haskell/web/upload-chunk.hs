{-# LANGUAGE OverloadedStrings #-}
import Web.Scotty
import qualified Data.List as DL
import qualified Data.ByteString as D
import qualified Data.ByteString.Char8 as DBC
import qualified Data.ByteString.Lazy as DBL
import qualified Data.Text.Lazy as DTL
import Data.Maybe
import Control.Monad
import Control.Monad.IO.Class
import Control.Monad.Trans.Class
import Network.Multipart
import Data.Map

{- cabal init -}
{- build-depends: base, scotty, wai, bytestring, text, multipart, containers, transformers -}
{- cabal run upload-chunk -}

getMultiPart (MultiPart x) = x

readFromBodyPartWriteFile :: BodyPart -> IO ()
readFromBodyPartWriteFile (BodyPart headers bytestring) = do
    let filename = DL.init $ DL.tail $ DTL.unpack $ DL.last $ DTL.splitOn "filename=" $ DTL.pack $ (fromList headers) ! (HeaderName "Content-Disposition")
    print "-------------"
    print filename
    print "-------------"
    DBL.writeFile filename DBL.empty
    DBL.appendFile filename bytestring

postChunk :: String -> ScottyM ()
postChunk pathName = 
    post (capture pathName) $ do
        ct <- header "Content-Type"
        liftIO $ print ct
        ct_ <- liftIO $ parseContentType $ DTL.unpack $ fromJust ct
        let bm = (fromList $ ctParameters ct_) ! "boundary"
        wb <- body
        let msg = parseMultipartBody bm wb
        liftIO $ traverse readFromBodyPartWriteFile $ getMultiPart msg
        return ()

chunkHtml :: String -> ScottyM ()
chunkHtml pathName =
    get (capture pathName) $ do
        {- for chunked upload in front -}
        addHeader "Transfer-Encoding" "chunked"
        {- multipart/form-data will make webkitboundary in body, and chunked post only once, not multiple post, but multiple IO String read -}
        let h1 = "<html lang=\"en-US\"> <head> <title>" <> pathName <> "</title><body>"
        let h2 = "<form enctype=\"multipart/form-data\" action=\"" <> pathName <> "\" method=\"post\">"
        let h3 = "<input type=\"file\" name=\"chunk-upload\" multiple=\"multiple\"><input type=\"submit\" value=\"Submit\"></form></body></html>"
        (html . DTL.pack) $ h1 <> h2 <> h3

main = do
    scotty 36000 $ do
    get "/" $ text "hi"
    postChunk "/chunk"
    chunkHtml "/chunk"




