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
import Data.Maybe

-- ./reverseBot hello

main :: IO ()
main = do
  l <- getArgs
  let inputMsg = pack $ head l
  manager <- newManager tlsManagerSettings
  token <- return $ Token "bot9"
  chatId <- return $ ChatId 7
  sendMsg chatId inputMsg token manager
  recvMsg token manager Nothing chatId

getResult :: [Update] -> [Maybe Text]
getResult  x = fmap (g . message) x
g = \(Just x) -> text x

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
recvMsg token manager upId chatId = do
  -- sleep 3
  resultEither <- getUpdates token upId (Just 100) (Just 30) manager
  case resultEither of
        Right Response { result = m }  -> do
            if Data.List.null m then do
                sleep 2
                recvMsg token manager upId chatId
            else do
            putStrLn "recv msg:"
            jm <- return $ message (head m)
            result <- return $ (\(Just i) -> i) jm
            print $ text result
            let updateId = getUpdateId m
            putStrLn "updateId is "
            print updateId
            let latestId = last updateId
            if (Just latestId == upId) then do
                sleep 2
                recvMsg token manager upId chatId
            else do
                putStr "latestId is "
                print latestId
                sendMsg chatId (T.reverse . fromJust . last . getResult $ m) token manager
                recvMsg token manager (Just latestId) chatId
                
--            if Data.List.null (tail updateId) then do
--                    latestId <- return $ head updateId
--                    if (not (Just latestId == upId)) then do
--                        result <- return $ (getResult m) \\ prevResult  -- remove the same element in result
--                        -- result :: [Maybe Text]
--                        putStr "recv: "
--                        sequenceA_ (fmap print result)
--                        -- putStr "[1]"
--                        -- print latestId
--                        sendMsg chatId (T.reverse $ takeIt $ head result) token manager
--                        recvMsg token manager (Just latestId) result chatId
--                    else do
--                        sleep 1
--                        recvMsg token manager (Just latestId) prevResult chatId
--            else do 
--                    let x = head . tail $ updateId
--                    if (not (Just x == upId)) then do
--                        result <- return $ (getResult m) \\ prevResult
--                        putStr "recv: "
--                        sequenceA_ (fmap print result)
--                        -- putStr "[1,2]"
--                        -- print x
--                        sendMsg chatId (T.reverse $ takeIt $ head result) token manager
--                        recvMsg token manager (Just x) result chatId
--                    else do
--                        sleep 1
--                        recvMsg token manager (Just x) prevResult chatId
                    
        Left e -> do
            putStr "error:"
            print e
        
