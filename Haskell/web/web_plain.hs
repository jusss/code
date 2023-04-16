{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
import Network.Wai
import Network.Wai.Parse
import Network.Wai.Handler.Warp (run)
import Web.Scotty
import Control.Monad
import Control.Monad.IO.Class
import System.IO
import System.Process
import Data.Time.Clock
import Data.Time.Clock.POSIX
import qualified Data.List as DL
import qualified Data.Text.Lazy as DTL
import qualified Data.ByteString.Char8 as BSC

addr = ""
rootPath = "/root/web_plain"
{- assume download file in /root/web_plain/video/ -}

main :: IO ()
main = do
    scotty 6000 $ do

        post "/url" $ do
            url <- param "/url"
            let urlData = BSC.unpack url
            liftIO $ print urlData
            _d <- liftIO $ getCurrentTime
            let _t = addUTCTime (60*60*8 :: NominalDiffTime) _d
            let _date = fmap (\x -> if x == ' ' then '.' else x) $ DL.take 19 $ show _t
            text $ DTL.pack $ addr <> "/video/" <> _date <> ".mp4"
            {- liftIO $ callCommand ("cd video; youtube-dl --no-mtime -o '" <> _date <> ".%(ext)s' " <> urlData) -}
            liftIO $ callCommand ("cd video;  yt-dlp \"" <> urlData <> "\" --cookies-from-browser \"chrome:/root/.config/chromium/Default::twitter\" -o '"     <> _date <> ".%(ext)s' ")

        get "/video/:file" $ do
            _file <- param "file"
            file $ rootPath <> "/video/" <> _file

        return ()
