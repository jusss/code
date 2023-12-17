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
import Control.Monad.IO.Class (liftIO)

local_ip = (0,0,0,0)
local_port = 0
remote_ip = (216,146,35,35)
remote_port = 53

main = do
    searchMap <- newMVar $ fromList [(0,SockAddrInet local_port $ tupleToHostAddress local_ip)]

    sock <- socket AF_INET Datagram 0
    bind sock $ SockAddrInet local_port $ tupleToHostAddress local_ip

    sockDns <- socket AF_INET Datagram 0
    connect sockDns $ SockAddrInet remote_port $ tupleToHostAddress remote_ip

    forkIO $ forever $ do
        (_msg, addr) <- recvFrom sock 10240
        let msg = reverse _msg
        -- print $ decode msg
        -- let qnames = (unpack <$>) . (qname <$>) . question $ decode msg
        -- print qname
        traverse (\a -> (fmap (<> a) (takeMVar searchMap)) >>= putMVar searchMap >>= \x -> sendAll sockDns msg) $ fmap ((\x -> fromList [(x,addr)]) . identifier . header) $ decode msg
    
    forever $ do
        msg <- recv sockDns 10240
        -- print $ decode msg
        let _r = decode msg
        -- traverse (\a -> print [(rrname x, rdata x) | x <- answer a]) $ _r
        let _r1 = fmap (\a -> [(rrname x, rdata x) | x <- answer a]) $ _r
        if _r1 /= Right [] then do
            traverse print _r1
            traverse (\x -> fmap (! x) (readMVar searchMap) >>= sendAllTo sock (reverse msg)) $ fmap (identifier . header) $ _r
        else
            fmap Right (print "empty list from dns server")
