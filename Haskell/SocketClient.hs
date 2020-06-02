{-# LANGUAGE OverloadedStrings #-}
module SocketClient where
import Network.Socket
import Network.Socket.ByteString (recv, sendAll)
import Data.ByteString
import Data.Text.Encoding
import Data.Text

main :: IO ()
main = do
    sock  <- socket AF_INET Stream 0
    let addr = SockAddrInet 30017 $ tupleToHostAddress (127, 0, 0, 1)
    connect sock addr
    sendAll sock $ encodeUtf8 ("Hello" :: Text)

