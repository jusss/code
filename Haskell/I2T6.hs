{-# LANGUAGE OverloadedStrings #-}

import Network.HTTP.Client      (newManager)
import Network.HTTP.Client.TLS  (tlsManagerSettings)
import Web.Telegram.API.Bot 
import Web.Telegram.API.Bot.Responses (UpdatesResponse)
import Data.Char
--import qualified Data.Text.IO as D
import Data.Text (pack, Text(..)) 
import System.IO hiding (getLine)
import System.Environment
import qualified Data.Text as T
--import Web.Telegram.API.Bot.API (Message(..))
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
import Data.Text.Encoding.Error
import System.Exit

-- telegram-api for haskell https://github.com/klappvisor/haskell-telegram-api
-- howItWorks :: yourTelegramAccount -> TelegramBot -> IRC2Telegram -> IRC

-- 1. create a bot from BotFather on telegram, then get its token and your telegram account's chatId, talk to that bot
-- 2. git clone haskell https://github.com/klappvisor/haskell-telegram-api.git then cd into it, cabal v2-build, put this file into that directory
-- 3. change the default irc user info in the file, then ghc IRC2TelegramM.hs, once done, run it

-- in your telegram account conversation with your telegram bot, send messages to irc syntax: #channel msg
-- send irc commands syntax: /COMMAND PARAMETERS

-- usage: 
-- #channel message
-- /time
-- /prefix #channel
-- /prefix nick
-- message
-- after you use `/prefix #channel' then you can send message directly

-----------------------------------------------------------------
-- change info here
-- irc        
_server = "irc.freenode.net"
_port = "6665"
_nick = "i"
_joinChannel = "#x"
-- telegram 
_token = "bot9"
_chatId = 7

--------------------------------------------------------------------

headMaybe :: [a] -> Maybe a
headMaybe [] = Nothing
headMaybe (x:xs) = Just x

tailMaybe :: [a] -> Maybe a
tailMaybe [] = Nothing
tailMaybe xs = headMaybe $ reverse xs


filterUtf8Exception :: Either UnicodeException Text -> Text
filterUtf8Exception x =
    case x of
        Right v -> v
        Left e -> "Non UTF8 character"


getResult :: [Update] -> [Maybe Text]
getResult  x = fmap (g . f) x
g (Just x) = text x
g Nothing = Nothing
f = message

getUpdateId :: [Update] -> [Int]
getUpdateId x = fmap (\i -> update_id i) x

sleep = threadDelay . ceiling . (*1000000)

takeIt :: Maybe (Maybe Text) -> Text
takeIt Nothing = " "
takeIt (Just Nothing) = " "
takeIt (Just (Just a)) = a

-- send msg to your telegram account by this bot api
sendMsg chatId inputMsg token manager = do
  let request = sendMessageRequest chatId inputMsg
  res <- sendMessage token request manager
  case res of
    Left e -> do
      putStr "sendMsg failed: "
      print e
    Right Response { result = m } -> do
      putStr "sent: "
      putStrLn $ (show $ message_id m) ++ " " ++ (show $ text m)

-- recv msg from telegram bot then send it to irc
recvMsg token manager upId prevResult chatId socket defaultPrefix  = do
  -- sleep 3
  resultEither <- getUpdates token upId (Just 100) (Just 0) manager
  case resultEither of
        Right Response { result = m }  -> do
            -- putStrLn "recv msg:"
            -- jm <- return $ message (head m)
            -- result <- return $ (\(Just i) -> i) jm
            -- print $ text result
            let updateId = getUpdateId m
            case (tailMaybe updateId) of
                Nothing -> recvMsg token manager upId prevResult chatId socket defaultPrefix
                Just x -> do
                    let latestId = x
                    if (not (Just latestId == upId)) then do
                        result <- return $ (getResult m) \\ prevResult  -- remove the same element in result
                        -- result :: [Maybe Text]
                        putStr "recv: "
                        sequenceA_ (fmap print result)
                        -- putStr "[1]"
                        -- print latestId
                        -- sendMsg chatId (T.reverse $ takeIt $ head result) token manager
                        let t2i = En.encodeUtf8 $ takeIt $ headMaybe result

                        case (D.isPrefixOf "/prefix " t2i) of
                             True -> recvMsg token manager (Just latestId) result chatId socket (D.drop 8 t2i)
                             False -> 
                                          case (D.isPrefixOf "/" t2i) of
                                                False -> sendAll socket $ sendToChannel t2i  defaultPrefix -- append prefix PRIVMSG
                                                True -> sendAll socket (D.drop 1 $ t2i <> "\r\n")  -- raw messages like "/TIME" or "/JOIN #channel", just drop "/" and send the rest to irc server
                        recvMsg token manager (Just latestId) result chatId socket defaultPrefix 
                        
                    else do
                        sleep 1
                        recvMsg token manager (Just latestId) prevResult chatId socket defaultPrefix 
                        -- now telegram api send and recv both are async, IRC send is non-blocked, only IRC recv is blocked.
                    
        Left e -> do
            putStr "recvMsg error:"
            print e

nick = "NICK " <> _nick <> "\r\n"
user = "USER xxx 8 * :xxx\r\n"
autoJoinChannel = "JOIN " <> _joinChannel <> "\r\n"

-- x is like "#channel msg", raw messages like "/JOIN #channel" or "/TIME", start with "/", just drop "/" and send the rest to irc server
sendToChannel x _defaultPrefix =
              if (D.isPrefixOf "#" x) then
                            "PRIVMSG " <> (fst (D.breakSubstring " " x)) <> " :" <> (D.drop 1 (snd (D.breakSubstring " " x))) <> "\r\n"
              else
                        "PRIVMSG " <> _defaultPrefix <> " :" <> x <> "\r\n"


-- filter prefix messages PRIVMSG QUIT JOIN PART
parseMsg :: D.ByteString -> D.ByteString -> D.ByteString
parseMsg x nick = case (D.isInfixOf " PRIVMSG #" x) of
    True -> 
        case (D.isInfixOf nick x) of 
            False ->
                (fst (D.breakSubstring ":" (snd $ D.breakSubstring "#" x))) <>  -- channel
                (D.drop 1 (fst $ D.breakSubstring "!" x)) <> ": " <>  -- nick
                (D.drop 1 (snd $ D.breakSubstring ":" (snd $ D.breakSubstring "#" x)))  -- message
            True ->
                (En.encodeUtf8 "\128994") <> -- an emoji circle highlight, decimal
                (fst (D.breakSubstring ":" (snd $ D.breakSubstring "#" x))) <>  -- channel
                (D.drop 1 (fst $ D.breakSubstring "!" x)) <> ": " <>  -- nick
                (D.drop 1 (snd $ D.breakSubstring ":" (snd $ D.breakSubstring "#" x)))  -- message
                
    False -> 
        if (D.isInfixOf " QUIT :" x) then  -- don't worry user send those messages, 'cause of matching PRIVMSG pattern first
            -- (D.drop 1 (fst $ D.breakSubstring "!" x)) <> " quit"
            "hide"
        else 
        if (D.isInfixOf " JOIN #" x) then 
            -- (D.drop 1 (fst $ D.breakSubstring "!" x)) <> " joined " <> (fst $ D.breakSubstring "\r\n" (snd $ D.breakSubstring "#" x))
            "hide"
        else 
        if (D.isInfixOf " PART #" x) then 
            -- (D.drop 1 (fst $ D.breakSubstring "!" x)) <> " parted " <> (fst $ D.breakSubstring "\r\n" (snd $ D.breakSubstring "#" x))
            "hide"
        else
        if (D.isInfixOf " NICK :" x) && (D.isInfixOf nick x) then
            "newNick-" <>  (D.drop 7 $ snd $ D.breakSubstring " NICK :" (fst $ D.breakSubstring "\r\n" x))
        else
        if (D.isInfixOf nick x) then
            (En.encodeUtf8 "\128994") <> x
        else 
            x

-- ":irc27313! ... NICK :xxx"

filterMsg x = ()

main :: IO ()
main = runTCPClient _server _port $ \socket -> do
    manager <- newManager tlsManagerSettings
    token <- return $ Token _token
    chatId <- return $ ChatId _chatId
    sendAll socket nick
    sendAll socket user
    sendAll socket autoJoinChannel

    threadId <- forkIO (recvMsg token manager Nothing [] chatId socket _nick)  -- send msg from telegram to irc            
    relayIRC2Tele token manager chatId socket threadId _nick
                        

-- relayIRC2Tele :: Socket -> ThreadId -> D.ByteString-> IO ()
relayIRC2Tele token manager chatId socket threadId nick = do
    msg <- recv socket 1024  -- msg :: ByteString
    if (D.length msg == 0) then do           --  irc disconnected
        print "IRC Disconnected, Re-connecting"
        killThread threadId      
        sleep 15
        -- main
        exitWith $ ExitFailure 22
    else
        case D.isPrefixOf "PING" msg of
            True -> do
                sendAll socket $ D.map (\i -> if (i == 73) then 79 else i) msg -- PING PONG
                relayIRC2Tele token manager chatId socket threadId nick
            False -> do
                let parseResult = parseMsg msg nick
                case (parseResult == "hide") of -- filter QUIT JOIN PART messages
                    True -> relayIRC2Tele token manager chatId socket threadId nick
                    False -> 
                        case (D.isPrefixOf "newNick-" parseResult) of
                            False -> do
                                sendMsg chatId (filterUtf8Exception $ En.decodeUtf8' $ parseMsg msg nick) token manager -- irc msg to telegram
                                relayIRC2Tele token manager chatId socket threadId nick
                            True -> do
                                let newNick = D.drop 8 parseResult
                                relayIRC2Tele token manager chatId socket threadId newNick                                 


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
