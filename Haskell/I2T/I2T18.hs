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
import Data.Char
import Data.Text (pack, Text(..))
import Data.Text.Encoding.Error 
import Data.Foldable (sequenceA_)
import qualified Data.Text as T
import Data.List as L
import qualified Data.ByteString as D
import qualified Data.Text.Encoding as En
import Control.Applicative hiding (many)
import qualified Data.ByteString.UTF8 as DBU
import System.Environment
import qualified Data.Text.IO as DTI
import Data.Int
import Data.Foldable as F

import Text.Parsec
import Text.ParserCombinators.Parsec hiding (try)
import Data.Either
import Data.Functor
import Data.Map hiding (filter, fromList)
import Data.Maybe

-- telegram-api for haskell https://github.com/klappvisor/haskell-telegram-api
-- howItWorks :: yourTelegramAccount -> TelegramBot -> IRC2Telegram -> IRC

-- 1. create a bot from BotFather on telegram, then get its token and your telegram account's chatId, talk to that bot
-- 2. git clone haskell https://github.com/klappvisor/haskell-telegram-api.git then cd into it, cabal v2-build, put this file into that directory
-- 3. change the default irc user info in the file, then ghc IRC2TelegramM.hs, once done, run it

-- in your telegram account conversation with your telegram bot, send messages to irc syntax: #channel msg
-- send irc commands syntax: /COMMAND PARAMETERS

-- usage: 
-- #channel message
-- /time      -- just other valid irc commands, start them with /
-- /prefix #channel
-- /prefix nick    -- it's equal to /msg or /query
-- /prefix #channel nick or /prefix #channel nick1 nick2
-- message  -- after you use `/prefix #channel' then you can send message directly

-- /set a #channel nick1 nick2  -- then 'a messgaes' replace 'a' with '#channel nick'
--- /unset  -- clear all the alias, 'a messages' will be send as it is

-- now this version, disable #channel prefix, use /whois nick to get which channel the people is from

-----------------------------------------------------------------


headMaybe :: [a] -> Maybe a
headMaybe [] = Nothing
headMaybe (x:xs) = Just x

tailMaybe :: [a] -> Maybe a
tailMaybe [] = Nothing
tailMaybe xs = Just $ last xs

filterUtf8Exception :: Either UnicodeException Text -> Text
filterUtf8Exception x =
    case x of
        Right v -> v
        Left e -> "Non UTF8 character"

sleep = threadDelay . ceiling . (*1000000)

takeIt :: Maybe (Maybe Text) -> Text
takeIt Nothing = " "
takeIt (Just Nothing) = " "
takeIt (Just (Just a)) = a

-- send msg to your telegram account by this bot api
-- https://github.com/klappvisor/haskell-telegram-api/blob/master/src/Web/Telegram/API/Bot/API/Messages.hs
-- sendMessage :: Token -> SendMessageRequest -> Manager -> IO (Either ClientError MessageResponse)
-- https://github.com/klappvisor/haskell-telegram-api/blob/master/src/Web/Telegram/API/Bot/Requests.hs

--data SendMessageRequest = SendMessageRequest { message_chat_id :: ChatId,
--message_text :: Text, 
--message_parse_mode :: Maybe ParseMode,
--message_disable_web_page_preview :: Maybe Bool,
--message_disable_notification :: Maybe Bool,
--message_reply_to_message_id :: Maybe Int,
--message_reply_markup :: Maybe ReplyKeyboard
--} deriving (Show, Generic)

sendMsg :: ChatId -> Text -> Token -> Manager -> IO ()
sendMsg chatId inputMsg token manager = do
  let request = sendMessageRequest chatId inputMsg
  res <- sendMessage token request manager
  case res of
    Left e -> do
      print $ "failed to send: " <> inputMsg
      putStr "sendMsg failed: "
      print e
    Right Response { result = m } -> do
      putStr "sent: "
      putStrLn $ (show $ message_id m) ++ " " ++ (show $ text m)

-- https://github.com/klappvisor/haskell-telegram-api/blob/master/src/Web/Telegram/API/Bot/API/Updates.hs
-- https://github.com/klappvisor/haskell-telegram-api/blob/master/src/Web/Telegram/API/Bot/Data.hs
-- data Update = Update  {
--    update_id            :: Int 
--  , message              :: Maybe Message 
--  , edited_message       :: Maybe Message 
--  , channel_post         :: Maybe Message 
--  , edited_channel_post  :: Maybe Message 
--  , inline_query         :: Maybe InlineQuery 
--  , chosen_inline_result :: Maybe ChosenInlineResult 
--  , callback_query       :: Maybe CallbackQuery 
--  , shipping_query       :: Maybe ShippingQuery 
--  , pre_checkout_query   :: Maybe PreCheckoutQuery 
-- } deriving (FromJSON, ToJSON, Show, Generic)

-- data Message = Message
--  { message_id :: Int, from :: Maybe User, date :: Int, chat :: Chat, forward_from :: Maybe User, forward_from_chat :: Maybe Chat, forward_from_message_id :: Maybe Int
--  , forward_signature :: Maybe Text, forward_date :: Maybe Int, reply_to_message :: Maybe Message, edit_date :: Maybe Int, media_group_id :: Maybe Text 
--  , author_signature :: Maybe Text, text :: Maybe Text, entities :: Maybe [MessageEntity], caption_entities :: Maybe [MessageEntity] ...}
-- https://github.com/klappvisor/haskell-telegram-api/blob/master/src/Web/Telegram/API/Bot/Data.hs

getResult :: [Update] -> [Maybe Text]
getResult  x = fmap (g . message) x
g :: Maybe Message -> Maybe Text
g (Just x) = text x
-- g Nothing = Nothing
g Nothing = Just "update message is Nothing"


-- relay Telegram bot messages to IRC
recvMsg :: Token -> Manager -> Maybe Int -> ChatId -> Socket -> T.Text -> Map T.Text T.Text -> IO ()
recvMsg token manager upId chatId socket defaultPrefix alistMap = do
  -- sleep 3
  -- getUpdates :: Token -> Maybe Int -> Maybe Int -> Maybe Int -> Manager-> IO (Either ClientError UpdatesResponse)
  resultEither <- getUpdates token upId (Just 100) (Just 0) manager
  -- resultEither :: Either ClientError UpdatesResponse
  case resultEither of
        -- type UpdatesResponse = Response [Update]
        -- data Response a = Response {result :: a , parameters :: Maybe ResponseParameters} deriving (Show, Generic, FromJSON)
        Right Response { result = m }  -> do
            -- m :: [Update]
            if L.null m then do
                        sleep 1
                        recvMsg token manager upId chatId socket defaultPrefix alistMap
            else do
            -- updateId :: [Int]
            let updateId = fmap update_id  m
            let latestId = last updateId
            if (Just latestId == upId) then do
                        sleep 1
                        recvMsg token manager (Just latestId) chatId socket defaultPrefix alistMap
                        -- now telegram api send and recv both are async, IRC send is non-blocked, only IRC recv is blocked.
            else do
                        -- t2i :: Text
                        let t2i = fromJust . last . getResult $ m
                        putStr "recv from Telegram: "
                        print t2i
                        
                        if | T.isPrefixOf "/prefix " t2i -> if | (L.length . T.words $ t2i) == 2 -> -- /prefix #channel or /prefix nick
                                                                 recvMsg token manager (Just latestId) chatId socket (T.drop 8 t2i) alistMap
                                                               | (L.length . T.words $ t2i) > 2 -> -- /prefix #channel nick or /prefix #channel nick1 nick2
                                                                 recvMsg token manager (Just latestId) chatId socket ((L.head . L.tail . T.words $ t2i) <> " :" <> (T.unwords . L.drop 2 . T.words $ t2i)) alistMap
                                                               | otherwise -> recvMsg token manager (Just latestId) chatId socket defaultPrefix alistMap -- just /prefix  

                           | not (T.isPrefixOf "/" t2i) -> if | T.any (== ' ') t2i ->  
                                                                sendAll socket $ sendToChannel (T.unwords $ (findAlias alistMap . Prelude.head . T.words $ t2i) : (tail . T.words $ t2i)) defaultPrefix
                                                              | otherwise -> sendAll socket $ sendToChannel t2i defaultPrefix -- append prefix PRIVMSG
                           | "/" == t2i -> sendAll socket $ sendToChannel t2i defaultPrefix
                           -- /set a #channel nick1 nick2
                           | T.isPrefixOf "/set " t2i -> recvMsg token manager (Just latestId) chatId socket defaultPrefix $ Data.Map.Strict.insert (Prelude.head . T.words . T.drop 5 $ t2i) (T.unwords . Prelude.tail . T.words . T.drop 5 $ t2i) alistMap
                           | "/unset" == t2i -> recvMsg token manager (Just latestId) chatId socket defaultPrefix Data.Map.Strict.empty
                           | otherwise -> sendAll socket $ En.encodeUtf8 (T.drop 1 $ t2i <> "\r\n")  -- raw messages like "/TIME" or "/JOIN #channel", just drop "/" and send the rest to irc server

                        recvMsg token manager (Just latestId) chatId socket defaultPrefix alistMap
                        
        Left e -> do
            putStr "recvMsg error:"
            print e
            exitWith $ ExitFailure 22 -- main can be IO () or IO a

findAlias :: Map Text Text -> Text -> Text
findAlias alistMap x = if Data.Map.Strict.empty == alistMap then x else if x `notMember` alistMap then x else (alistMap ! x)


-- x is like "#channel msg", raw messages like "/JOIN #channel" or "/TIME", start with "/", just drop "/" and send the rest to irc server
sendToChannel :: Text -> Text -> D.ByteString
sendToChannel x _defaultPrefix =
              if (T.isPrefixOf "#" x) then
                  En.encodeUtf8 ("PRIVMSG " <> (L.head . T.words $ x) <> " :" <> (T.unwords . L.tail . T.words $ x) <> "\r\n")
              else
                  En.encodeUtf8 ("PRIVMSG " <> _defaultPrefix <> " :" <> x <> "\r\n")

toText :: D.ByteString -> Text
toText = En.decodeUtf8With lenientDecode

-- :nick!~nick@1700:bef1:5e10::1 PRIVMSG #channel :words
-- :nick!~user@unaffiliated/user PRIVMSG #channel :words
-- :*.net*.split
-- :nick!user@gateway/web/irc JOIN
-- ":irc27313! ... NICK :xxx"

getElem :: Int -> [a] -> Maybe a
getElem n = fmap fst . L.uncons . L.drop n

reduce f (x:xs) = L.foldl f x xs
isContained :: [Text] -> Text -> Bool
isContained xs msg = reduce (&&) . fmap (`T.isInfixOf` msg) $ xs

-- parsePRIVMSG ":nick!~user@addr PRIVMSG #channel :words" == Just "#channel nick :words"
parsePRIVMSGNormal :: Text -> Maybe Text
parsePRIVMSGNormal x = if isContained ["!","@"," PRIVMSG "] x then
                 (getElem 2 . T.words $ x) -- channel
                 <> (Just . T.replace ":" " " . L.head . T.splitOn "!" $ x) -- nick
                 <> (Just " ") <> (Just . T.unwords . L.drop 3 . T.words $ x) -- words
                 else Just x

-- filter prefix messages PRIVMSG QUIT JOIN PART
parseMsgNormal :: Text -> Text -> Maybe Text
parseMsgNormal nick x = 
    if | isContained ["!", "@", " PRIVMSG #"] x -> if | T.isInfixOf nick x -> Just "\128994" <> (parsePRIVMSGNormal x)
                                                      | otherwise -> parsePRIVMSGNormal x
       | isContained ["!", "@", " PRIVMSG "] x -> Just "\128994" <>  ((T.unwords . L.tail . T.words) <$> (parsePRIVMSGNormal x)) -- in case raw cmd help "PRIVMSG JOIN..."
       | T.isPrefixOf "PING " x -> Nothing
       | isContained ["!", "@", " QUIT"] x -> Nothing
       | isContained ["!", "@", " JOIN #"] x -> Nothing
       | isContained ["!", "@", " PART #"] x -> Nothing
       | T.isInfixOf ":*.net*.split" x -> Nothing
       | isContained ["!", "@", " NICK :", nick] x -> Just "newNick" <> (getElem 2 . T.words $ x) -- Just "newNick:nick"
       | T.isInfixOf nick x -> Just $ "\128994" <> x
       | (L.length . T.words $ x) == 4 -> if | (L.head . L.tail . T.words $ x) == "PONG" -> Nothing
                                             | otherwise -> Just x
       | otherwise -> Just x

-- parsePRIVMSG ":nick!~user@addr PRIVMSG #channel :words" == Just "#channel nick :words"
parsePRIVMSGLite :: Text -> Text -> Maybe Text
parsePRIVMSGLite nick x = if isContained ["!","@"," PRIVMSG #"] x then -- public message
                 -- (getElem 2 . T.words $ x) -- channel
                 (Just . T.replace ":" " " . L.head . T.splitOn "!" $ x) -- nick
                 <> (Just " ") <> (Just . T.unwords . L.drop 3 . T.words $ x) -- words
                 else if isContained ["!","@"," PRIVMSG " <> nick] x then -- private msg
                 Just "private " <> (getElem 2 . T.words $ x) -- nick
                 <> (Just . T.replace ":" " " . L.head . T.splitOn "!" $ x) -- nick
                 <> (Just " ") <> (Just . T.unwords . L.drop 3 . T.words $ x) -- words
                 else Just x

-- filter prefix messages PRIVMSG QUIT JOIN PART
parseMsgLite :: Text -> Text -> Maybe Text
parseMsgLite nick x = 
    if | isContained ["!", "@", " PRIVMSG #"] x -> if | T.isInfixOf nick x -> Just "\128994" <> (parsePRIVMSGLite nick x)
                                                      | otherwise -> parsePRIVMSGLite nick x
       | isContained ["!", "@", " PRIVMSG "] x -> Just "\128994" <>  (parsePRIVMSGLite nick x) -- in case raw cmd help "PRIVMSG JOIN..."
       | T.isPrefixOf "PING " x -> Nothing
       | isContained ["!", "@", " QUIT"] x -> Nothing
       | isContained ["!", "@", " JOIN #"] x -> Nothing
       | isContained ["!", "@", " PART #"] x -> Nothing
       | T.isInfixOf ":*.net*.split" x -> Nothing
       | isContained ["!", "@", " NICK :", nick] x -> Just "newNick" <> (getElem 2 . T.words $ x) -- Just "newNick:nick"
       | T.isInfixOf nick x -> Just $ "\128994" <> x
       | (L.length . T.words $ x) == 4 -> if | (L.head . L.tail . T.words $ x) == "PONG" -> Nothing
                                             | otherwise -> Just x
       | otherwise -> Just x

relayIRC2Tele :: Token -> Manager -> ChatId -> Socket ->  Text -> [Text] -> Text -> Text -> (Text -> Text -> Maybe Text) -> IO a
relayIRC2Tele token manager chatId socket nick nickList userCmd autoJoinChannelCmd parseMsg = do
    msg <- recv socket 1024  -- msg :: ByteString
    if | D.length msg == 0 -> do           --  irc disconnected
                        print "IRC Disconnected, Re-connecting"
                        -- sleep 15
                        -- main
                        exitWith $ ExitFailure 22 -- main can be IO () or IO a
       | otherwise -> do
            let msgList = L.filter (/= "") . T.splitOn "\r\n" . toText $ msg
            if | L.any (T.isPrefixOf "PING") msgList -> -- contain PING msg
                            sendAll socket (En.encodeUtf8 ("PO" <> (T.drop 2 . L.head . L.filter (T.isPrefixOf "PING") $ msgList) <> "\r\n"))
               | otherwise -> return ()

            if | L.any (T.isSuffixOf ":Nickname is already in use.") msgList -> do
                            sendAll socket $ En.encodeUtf8 ("NICK " <> (L.head nickList) <> "\r\n")
                            sendAll socket $ En.encodeUtf8 userCmd
                            sendAll socket $ En.encodeUtf8 autoJoinChannelCmd
                            relayIRC2Tele token manager chatId socket (L.head nickList) (L.tail nickList) userCmd autoJoinChannelCmd parseMsg 
               | otherwise -> return ()

            let parsedList = catMaybes . fmap (parseMsg nick) $ msgList
            if | L.null parsedList -> relayIRC2Tele token manager chatId socket nick nickList userCmd autoJoinChannelCmd parseMsg -- only contain PING or PART or JOIN sort of messages
               | not . L.any (T.isPrefixOf "newNick:") $ parsedList -> do -- do not contain new nick
                            -- sequenceA_ (fmap (\msg -> sendMsg chatId (msg <> "\r\n") token manager) parsedList)
                            sendMsg chatId (foldl1 (<>) . fmap (<> "\r\n") $ parsedList) token manager
                            relayIRC2Tele token manager chatId socket nick nickList userCmd autoJoinChannelCmd parseMsg 
               | L.all (T.isPrefixOf "newNick:") parsedList -> -- only contain new nick
                            relayIRC2Tele token manager chatId socket (T.drop 8 . L.head $ parsedList) nickList userCmd autoJoinChannelCmd parseMsg
               | otherwise -> do -- contain new nick and other messages
                            -- sequenceA_ (fmap (\msg -> sendMsg chatId (msg <> "\r\n") token manager) (L.filter (not . T.isPrefixOf "newNick:") parsedList))
                            sendMsg chatId (foldl1 (<>) . fmap (<> "\r\n") . L.filter (not . T.isPrefixOf "newNick:") $ parsedList) token manager
                            relayIRC2Tele token manager chatId socket (T.drop 8 . L.head . L.filter (T.isPrefixOf "newNick:") $ parsedList) nickList userCmd autoJoinChannelCmd parseMsg

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

-- timer to detect if remote disconnect
detectDisconnected :: Socket -> String -> IO ()
detectDisconnected socket server = do
    r <- E.try (sendAll socket . En.encodeUtf8 $ "PING " <> (pack server) <> "\r\n") :: IO (Either E.SomeException ())
    case r of
        Left ex -> do
                        print "Ping TimeOut, Remote Disconnected Without A Signal"
                        -- killThread threadId      
                        -- sleep 15
                        -- main
                        exitWith $ ExitFailure 22 -- main can be IO () or IO a
        Right value -> do
            sleep 300
            detectDisconnected socket server

checkException :: [Async a] -> IO ()
checkException alist = do
    currentState <- sequenceA (fmap poll alist) -- sequenceA will do natural transform, turn [IO (Maybe (Either SomeException a))] to IO [Maybe (Either SomeException a)]
    -- poll :: Async a -> IO (Maybe (Either SomeException a))
    -- if Async is running, return Nothing, exit with successful, return Just (Right value), exit with exception, return Just (Left exception)
    -- if L.null $ catMaybes currentState then do
    if isNothing $ foldl1 (Control.Applicative.<|>) currentState then do
            sleep 60
            checkException alist
    else
       exitWith $ ExitFailure 22

list2Tuple [a,b] = (a,b)

filterComments :: Text -> Text -> Text
filterComments commentSymbol = L.head . T.splitOn commentSymbol

filterSpaces :: Text -> Text
filterSpaces = T.filter (/= ' ')

filterNewLines :: Text -> [Text]
filterNewLines =  T.splitOn "\n" . T.replace "\r" "\n"

filterEmptyStrings :: [Text] -> [Text]
filterEmptyStrings = L.filter (/= "")

-- syntax like `a op b`, infix expression, not prefix or postfix
checkSyntax :: Text -> Text -> Either Text Text
checkSyntax op txt = if | T.isInfixOf op txt -> if | (L.length . splitWith op $ txt) == 2 -> Right txt
                                                   | otherwise -> Left txt
                        | otherwise -> Left txt

splitWith :: Text -> Text -> [Text]
splitWith x xs = L.filter (/= "") . T.splitOn x $ xs

parseComment :: Parser (Maybe (String,String))
parseComment = try $ do
    spaces
    string "--"
    c <- manyTill anyChar newline
    spaces
    return Nothing

parseAssign :: Parser (Maybe (String,String))
parseAssign = try $ do
  spaces
  k <- many letter
  spaces
  char '='
  spaces
  v <- many (noneOf "\n ")
  spaces
  return $ Just (k,v)

parseInvalid :: Parser (Maybe (String, String))
parseInvalid = try $ do
    spaces
    manyTill anyChar newline
    spaces
    return Nothing

findIn :: String -> Either ParseError (Map String String) -> Maybe String
findIn key (Right m) = fromRight Nothing $ fmap (!? key) (Right m)
findIn key (Left m) = Nothing

main = do
    fileName <- getArgs
    if (L.null fileName) then
        putStrLn "it needs a config file"
    else do
        context <- readFile $ L.head fileName

        let r2 = parse (many (parseComment Text.ParserCombinators.Parsec.<|> parseAssign  Text.ParserCombinators.Parsec.<|> parseInvalid)) "" context
        print r2
        let r3 = fmap (L.filter (/= Nothing)) r2
        if (Right [] == r3) then print "no assignment, just comments and invalid styles" >> (exitWith $ ExitFailure 22)
        else do
            print r3 -- Right [Just ("a","b")]
            let r9 = fmap fromList (fmap (fmap fromJust) r3)
            print r9 -- Right fromList [("a","b")]

            let rx1 = findIn "mode" r9
            mode <- if (rx1 == Nothing) then print "mode not found" >> (exitWith $ ExitFailure 22) else return $ fromJust rx1
            let rx2 = findIn "server" r9
            server <- if (rx2 == Nothing) then print "server not found" >> (exitWith $ ExitFailure 22) else return $ fromJust rx2
            let rx3 = findIn "port" r9
            port <- if (rx3 == Nothing) then print "port not found" >> (exitWith $ ExitFailure 22) else return $ fromJust rx3
            let rx4 = findIn "nick" r9
            nick <- if (rx4 == Nothing) then print "nick not found" >> (exitWith $ ExitFailure 22) else return $ T.pack $ fromJust rx4
            let rx5 = findIn "channel" r9
            autoJoinChannel <- if (rx5 == Nothing) then print "channel not found" >> (exitWith $ ExitFailure 22) else return $ T.pack $ fromJust rx5
            let rx6 = findIn "token" r9
            _token <- if (rx6 == Nothing) then print "token not found" >> (exitWith $ ExitFailure 22) else return $ T.pack $ fromJust rx6
            let rx7 = findIn "chatId" r9
            _chatId <- if (rx7 == Nothing) then print "chatId not found" >> (exitWith $ ExitFailure 22) else return $ (read $ fromJust rx7 :: Int64)
            let nickCmd = "NICK " <> nick <> "\r\n" :: Text
            let userCmd = "USER xxx 8 * :xxx\r\n" :: Text
            let autoJoinChannelCmd = "JOIN " <> autoJoinChannel <> "\r\n" :: Text
            -- nickList :: [Text]
            let nickList = fmap T.pack . L.permutations . T.unpack $ nick
            runTCPClient server port $ \socket -> do
                manager <- newManager tlsManagerSettings
                token <- return $ Token _token
                chatId <- return $ ChatId _chatId
                sendAll socket $ En.encodeUtf8 nickCmd
                sendAll socket $ En.encodeUtf8 userCmd
                sendAll socket $ En.encodeUtf8 autoJoinChannelCmd
                -- t2IRC Telegram to IRC
                t2IRC <- async (recvMsg token manager Nothing chatId socket nick Data.Map.Strict.empty)
                -- pingMsg send PING per minute
                pingMsg <- async (detectDisconnected socket server)
                if | mode == "normal" -> do
                        -- irc2T IRC to Telegram
                        irc2T <- async (relayIRC2Tele token manager chatId socket nick nickList userCmd autoJoinChannelCmd parseMsgNormal)
                        checkException [t2IRC, pingMsg, irc2T]
                   | mode == "lite" -> do
                        --  irc2T IRC to Telegram
                        irc2T <- async (relayIRC2Tele token manager chatId socket nick nickList userCmd autoJoinChannelCmd parseMsgLite)
                        checkException [t2IRC, pingMsg, irc2T]
                   | otherwise -> do 
                        putStrLn "wrong mode parameter, it should be 'normal' or 'lite'"
                        exitWith $ ExitFailure 22 -- main can be IO () or IO a
