{-# LANGUAGE OverloadedStrings #-}

import Network.HTTP.Client      (newManager)
import Network.HTTP.Client.TLS  (tlsManagerSettings)
import Web.Telegram.API.Bot 
import Web.Telegram.API.Bot.Responses (UpdatesResponse)
import Data.Char
import qualified Data.Text.IO as D -- put qualified keyword will not import all the stuff of Data.Text.IO
import Data.Text (pack, Text(..)) 
import System.IO hiding (getLine)
import System.Environment
import qualified Data.Text as T
--import Web.Telegram.API.Bot.API (Message(..)) -- import all the data defined in data Message
import Data.Foldable (sequenceA_)
import Control.Monad
import Control.Concurrent
import Data.List 
import qualified Control.Exception as E
import qualified Data.ByteString.Char8 as C
import Network.Socket hiding (recv)
import Network.Socket.ByteString (recv, sendAll)
import qualified Data.ByteString as D
import qualified Data.Text.Encoding as En
import Control.Concurrent.Async

-- main :: IO ()
-- main = do
--   -- hSetBuffering stdout NoBuffering
--   l <- getArgs
--   -- s <- D.getLine
--   -- message <- return $ T.pack $ head l  -- T.pack $ head l is a value, so use return to make it as a IO action, then get the value from the action and bind it to message
--   -- eqaul to `let message = T.pack $ head l'
--   -- inputMsg :: Text
--   let inputMsg = pack $ head l
--   manager <- newManager tlsManagerSettings
--   token <- return $ Token "bot9"
--   chatId <- return $ ChatId 7
--   sendMsg chatId inputMsg token manager
--   recvMsg token manager Nothing [] chatId
-- 
--



getResult :: [Update] -> [Maybe Text]
getResult  x = fmap (g . f) x
g = \(Just x) -> text x
f = \i -> message i

getUpdateId :: [Update] -> [Int]
getUpdateId x = fmap (\i -> update_id i) x

sleep = threadDelay . ceiling . (*1000000)
takeIt :: Maybe Text -> Text
takeIt (Just a) = a
takeIt Nothing = pack "takeIt failed"

-- send msg
sendMsg chatId inputMsg token manager = do
  let request = sendMessageRequest chatId inputMsg
  res <- sendMessage token request manager
  case res of
    Left e -> do
      putStr "sent failed: "
      print e
    Right Response { result = m } -> do
      putStr "sent: "
      putStrLn $ (show $ message_id m) ++ " " ++ (show $ text m)

-- recv msg
recvMsg token manager upId prevResult chatId socket = do
  -- sleep 3
  resultEither <- getUpdates token upId (Just 100) (Just 30) manager
  case resultEither of
        Right Response { result = m }  -> do
            -- putStrLn "recv msg:"
            -- jm <- return $ message (head m)
            -- result <- return $ (\(Just i) -> i) jm
            -- print $ text result
            let updateId = getUpdateId m
            case (tail updateId) of
                [] -> do
                    latestId <- return $ head updateId
                    if (not (Just latestId == upId)) then do
                        result <- return $ (getResult m) \\ prevResult  -- remove the same element in result
                        -- result :: [Maybe Text]
                        putStr "recv: "
                        sequenceA_ (fmap print result)
                        -- putStr "[1]"
                        -- print latestId
                        -- sendMsg chatId (T.reverse $ takeIt $ head result) token manager
                        let t2i = En.encodeUtf8 $ takeIt $ head result 
                        case (D.isPrefixOf "/" t2i) of
                            False -> sendAll socket $ sendToChannel <> t2i <> "\r\n" -- append prefix PRIVMSG
                            True -> sendAll socket (D.drop 1 $ t2i <> "\r\n")  -- raw message
                        recvMsg token manager (Just latestId) result chatId socket 
                        
                    else do
                        sleep 1
                        recvMsg token manager (Just latestId) prevResult chatId socket 
                x:[] -> do
                    if (not (Just x == upId)) then do
                        result <- return $ (getResult m) \\ prevResult
                        putStr "recv: "
                        sequenceA_ (fmap print result)
                        -- putStr "[1,2]"
                        -- print x
                        -- sendMsg chatId (T.reverse $ takeIt $ head result) token manager
                        let t2i = En.encodeUtf8 $ takeIt $ head result
                        case (D.isPrefixOf "/" t2i) of
                            False -> sendAll socket $ sendToChannel <> t2i <> "\r\n" -- append prefix PRIVMSG
                            True -> sendAll socket (D.drop 1 $ t2i <> "\r\n")  -- raw message
                        recvMsg token manager (Just x) result chatId socket 

                    else do
                        sleep 1
                        recvMsg token manager (Just x) prevResult chatId socket 
                        -- now telegram api send and recv both are async, IRC send is non-blocked, only IRC recv is blocked.
                    
        Left e -> do
            putStr "error:"
            print e
-----------------------------------------------------------------
-- change info here
-- irc
_server = "irc.freenode.net"
_port = "6665"
_nick = "nick"
_channel = "#channel"
--telegram
_token = "bot9"
_chatId = 7

--------------------------------------------------------------------

nick = "NICK " <> _nick <> "\r\n"
user = "USER xxx 8 * :xxx\r\n"
_joinChannel = "JOIN " <> _channel <> "\r\n"
sendToChannel = "PRIVMSG " <> _channel <> " :"

-- filter prefix messages PRIVMSG QUIT JOIN PART
-- parseMsg :: ByteString -> ByteString
parseMsg x = case (D.isInfixOf sendToChannel x) of
    True -> (D.drop 1 (fst $ D.breakSubstring "!" x)) <> ": " <>
            (D.drop 1 (snd $ D.breakSubstring ":" (snd $ D.breakSubstring "!" x)))
    False -> 
        if (D.isInfixOf " QUIT :" x) then  -- don't worry user send those messages, 'cause of matching PRIVMSG pattern first
            (D.drop 1 (fst $ D.breakSubstring "!" x)) <> " quit" 
        else 
        if (D.isSuffixOf _joinChannel x) then 
            (D.drop 1 (fst $ D.breakSubstring "!" x)) <> " joined"
        else 
        if (D.isSuffixOf ("PART " <> _channel <> "\r\n") x) then 
            (D.drop 1 (fst $ D.breakSubstring "!" x)) <> " parted"
        else 
            x


main :: IO ()
main = runTCPClient _server _port $ \socket -> do
    manager <- newManager tlsManagerSettings
    token <- return $ Token _token
    chatId <- return $ ChatId _chatId
    sendAll socket nick
    sendAll socket user
    sendAll socket _joinChannel
    forkIO (forever $ do
        msg <- recv socket 1024  -- msg :: ByteString
        case D.isPrefixOf "PING" msg of
             True -> sendAll socket $ D.map (\i -> if (i == 73) then 79 else i) msg -- PING PONG
             False -> sendMsg chatId (En.decodeUtf8 $ parseMsg msg) token manager) -- send msg from irc to telegram 
    recvMsg token manager Nothing [] chatId socket -- send msg from telegram to irc

-- from the "network-run" package.
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
