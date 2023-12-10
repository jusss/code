{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE MultiWayIf #-}

import Network.HTTP.Client (Manager)
import Network.HTTP.Client      (newManager)
import Network.HTTP.Client.TLS  (tlsManagerSettings)
import Network.Socket hiding (recv)
import Network.Socket.ByteString (recv, sendAll)
import Web.Telegram.API.Bot 
import Web.Telegram.API.Bot.Responses (UpdatesResponse)
import System.IO hiding (getLine)
import System.Environment
import System.Exit
import Control.Monad
import Control.Concurrent
import Control.Concurrent.Async
import qualified Control.Exception as E
import Data.Map.Strict
import Data.Maybe
import Data.Char
import Data.Text (pack, Text(..))
import Data.Text.Encoding.Error 
import Data.Foldable (sequenceA_)
import qualified Data.Text as T
import Data.List as L
import qualified Data.ByteString as D
import qualified Data.Text.Encoding as En
import Control.Applicative
import qualified Data.ByteString.UTF8 as DBU
server = "irc.freenode.net"
port = "6665"
nick = "a" :: T.Text
autoJoinChannel = "#c"

nickList = fmap DBU.fromString . L.permutations . T.unpack $ nick

runTCPClient :: HostName -> ServiceName -> (Socket -> IO a) -> IO a
runTCPClient host port client = withSocketsDo $ do
    addr <- resolve
    E.bracket (open addr) close client
  where
    resolve = do
        let hints = defaultHints { addrSocketType = Stream }
        head <$> getAddrInfo (Just hints) (Just host) (Just port)
    open addr = do
        sock <- socket (addrFamily addr) (addrSocketType addr) (addrProtocol addr)
        connect sock $ addrAddress addr
        return sock

sleep = threadDelay . ceiling . (*1000000)

nickCmd = "NICK " <> nick <> "\r\n"
userCmd = "USER xxx 8 * :xxx\r\n"
autoJoinChannelCmd = "JOIN " <> autoJoinChannel <> "\r\n"

toText :: D.ByteString -> Text
toText = En.decodeUtf8With lenientDecode


recvMsg socket nickList = do
    msg <- recv socket 1024
    print msg
    let msgList = L.filter (/= "") . T.splitOn "\r\n" . toText $ msg
    if | L.any (T.isSuffixOf ":Nickname is already in use.") msgList -> do
            sendAll socket $ "NICK " <> (head nickList) <> "\r\n"
            recvMsg socket $ tail nickList

       | (D.length msg) == 0 -> do
                         exitWith $ ExitFailure 22
       | otherwise -> recvMsg socket nickList

main :: IO ()
main = runTCPClient server port $ \socket -> do
    sendAll socket $ En.encodeUtf8 nickCmd
    sendAll socket $ En.encodeUtf8 userCmd
    sendAll socket $ En.encodeUtf8 autoJoinChannelCmd
    recvMsg socket nickList
    
