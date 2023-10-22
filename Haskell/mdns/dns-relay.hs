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
import Data.List (or, isInfixOf)
import Data.ByteString.Char8 (unpack)

local_ip = (0,0,0,0)
local_port = 53
remote_ip = (8,8,8,8)
remote_port = 53
blacklist = [
    ".cnzz.com",
    "hm.baidu.com",
    ".dlrtz.com",
    "whweitkeji.com",
    ".0efghij.com",
    ".shuyu2001.cn",
    ".xn--yets68azjb.cn",
    ".0ghijkl.com",
    ".maimn.com",
    ".shdndn2.cn"]

main = do
    searchMap <- newMVar $ fromList [(0,SockAddrInet local_port $ tupleToHostAddress local_ip)]

    sock <- socket AF_INET Datagram 0
    bind sock $ SockAddrInet local_port $ tupleToHostAddress local_ip

    sockDns <- socket AF_INET Datagram 0
    connect sockDns $ SockAddrInet remote_port $ tupleToHostAddress remote_ip

    forkIO $ forever $ do
        (msg, addr) <- recvFrom sock 10240
        {- print $ decode msg -}
        {- traverse (\x -> print $ qname <$> question x) $ decode msg -}
        let _query = ((qname <$>) . question) <$> decode msg
        case _query of 
            Left x -> print _query
            Right y -> do
                if or [isInfixOf i _y | i <- blacklist, _y <- (unpack <$> y)] then do
                    traverse print $ ("blacked: " <>) <$> (unpack <$> y)
                    return ()
                else do
                    traverse (\a -> (fmap (<> a) (takeMVar searchMap)) >>= putMVar searchMap >>= \x -> sendAll sockDns msg) $ fmap ((\x -> fromList [(x,addr)]) . identifier . header) $ decode msg
                    print y
    
    forever $ do
        msg <- recv sockDns 10240
        {- print $ decode msg -}
        traverse (\a -> print [(rrname x, rdata x) | x <- answer a]) $ decode msg
        traverse (\x -> fmap (! x) (readMVar searchMap) >>= sendAllTo sock msg) $ fmap (identifier . header) $ decode msg
