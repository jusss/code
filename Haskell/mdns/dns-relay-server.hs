import Control.Monad (forever, liftM2)
import Network.Socket
import Network.Socket.ByteString (recv, recvFrom, sendAll, sendAllTo)
import Network.DNS.Decode
import Network.DNS.Types
import Control.Concurrent (forkIO)
import Control.Concurrent.MVar
import Data.Map.Strict
import Data.ByteString (reverse)
import Prelude hiding (reverse)

local_ip = (0,0,0,0)
local_port = 60053
remote_ip = (8,8,8,8)
remote_port = 53

main = do
    searchMap <- newMVar $ fromList [(0,SockAddrInet local_port $ tupleToHostAddress local_ip)]

    -- as server, bind with special port then recv data with random port, and reply to random port
    sock <- socket AF_INET Datagram 0
    bind sock $ SockAddrInet local_port $ tupleToHostAddress local_ip

    -- as client, connect remote with special port then send and recv with socket without port
    sockDns <- socket AF_INET Datagram 0
    connect sockDns $ SockAddrInet remote_port $ tupleToHostAddress remote_ip

    forkIO $ forever $ do
        (_msg, addr) <- recvFrom sock 10240
        let msg = reverse _msg
        print $ decode msg
        traverse (\a -> (fmap (<> a) (takeMVar searchMap)) >>= putMVar searchMap >>= \x -> sendAll sockDns msg) $ fmap ((\x -> fromList [(x,addr)]) . identifier . header) $ decode msg
    
    forever $ do
        msg <- recv sockDns 10240
        print $ decode msg
        traverse (\x -> fmap (! x) (readMVar searchMap) >>= sendAllTo sock (reverse msg)) $ fmap (identifier . header) $ decode msg
