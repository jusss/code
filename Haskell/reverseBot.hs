{-# LANGUAGE OverloadedStrings #-}

-- https://github.com/klappvisor/haskell-telegram-api
-- create a robot from BotFather on telegram, and get the token, also your telegram's chatId

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

main :: IO ()
main = do
  -- hSetBuffering stdout NoBuffering
  l <- getArgs
  -- s <- D.getLine
  -- message <- return $ T.pack $ head l  -- T.pack $ head l is a value, so use return to make it as a IO action, then get the value from the action and bind it to message
  -- eqaul to `let message = T.pack $ head l'
  -- inputMsg :: Text
  let inputMsg = pack $ head l
  manager <- newManager tlsManagerSettings
  token <- return $ Token "bot9-write-your-token-here"
  chatId <- return $ ChatId 7 -- your telegram chatId, get it from @chatid_echo_bot
  sendMsg chatId inputMsg token manager
  recvMsg token manager Nothing [] chatId

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
recvMsg token manager upId prevResult chatId = do
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
                        sendMsg chatId (T.reverse $ takeIt $ head result) token manager
                        recvMsg token manager (Just latestId) result chatId
                    else do
                        sleep 1
                        recvMsg token manager (Just latestId) prevResult chatId
                x:[] -> do
                    if (not (Just x == upId)) then do
                        result <- return $ (getResult m) \\ prevResult
                        putStr "recv: "
                        sequenceA_ (fmap print result)
                        -- putStr "[1,2]"
                        -- print x
                        sendMsg chatId (T.reverse $ takeIt $ head result) token manager
                        recvMsg token manager (Just x) result chatId
                    else do
                        sleep 1
                        recvMsg token manager (Just x) prevResult chatId
                    
        Left e -> do
            putStr "error:"
            print e
        
