{-# LANGUAGE OverloadedStrings #-}

import Network.HTTP.Client      (newManager)
import Network.HTTP.Client.TLS  (tlsManagerSettings)
import Web.Telegram.API.Bot
import Data.Char
-- import qualified Data.Text.IO as P
import qualified Data.Text.IO (getLine) -- put qualified keyword will make getLine from Data.Text.IO, not System.IO or Prelude
-- import qualified Data.Text as T  -- made diffrent with other module.pack
import Data.Text (pack)
import System.IO hiding (getLine)
import System.Environment

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  l <- getArgs
  -- s <- getLine
  -- message <- return $ T.pack $ head l  -- T.pack $ head l is a value, so use return to make it as a IO action, then get the value from the action and bind it to message
  let message = pack $ head l
  manager <- newManager tlsManagerSettings
  let request = sendMessageRequest chatId message
  res <- sendMessage token request manager
  case res of
    Left e -> do
      putStrLn "Request failed"
      print e
    Right Response { result = m } -> do
      putStrLn "Request succeded"
      print $ message_id m
      print $ text m
  where token = Token "bot9:U"
        chatId = ChatId 7