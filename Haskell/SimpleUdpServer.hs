module Main where

import Control.Monad (forever)
import Network.Socket
import Network.Socket.ByteString (recvFrom, sendAll)
import Network.DNS.Decode
import Network.DNS.Types

ip = (127,0,0,1)
port = 53

main :: IO ()
main = do
    sock <- socket AF_INET Datagram 0
    bind sock $ SockAddrInet port $ tupleToHostAddress ip
    forkIO $ forever $ do
        (msg, addr) <- recvFrom sock 1024
        case decode msg of
            Left m -> print m
            Right m -> print $ fmap qname (question m)
