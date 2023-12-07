{-# LANGUAGE ScopedTypeVariables #-}
import Control.Monad (forever, liftM2)
import Network.Socket
import Network.Socket.ByteString (recv, recvFrom, sendAll, sendAllTo)
import Network.DNS.Decode (decode)
import Network.DNS.Types
import Control.Concurrent (forkIO)
import Control.Concurrent.MVar
import Data.Map.Strict
import Data.ByteString (reverse)
import Prelude hiding (reverse)
import Data.List (or, isInfixOf, replicate)
import Data.ByteString.Char8 (unpack)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Except

local_ip = (0,0,0,0)
local_port = 53
remote_ip = ()
remote_port = 0
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
    ".jhzpgw.com.",
    ".xfkye.com.",
    "uk.qwkte.com.",
    "qye.zabaow.com.",
    "kme.rbbrao.com.",
    ".qoqaoligei.com",
    ".lzzyimg.com",
    ".wujinpp.com",
    ".1cpkcnm.com",
    ".lmabc001.com",
    ".taopianimage1.com",
    ".shdndn2.cn"]

main = do
    searchMap <- newMVar $ fromList [(0,SockAddrInet local_port $ tupleToHostAddress local_ip)]

    -- as server, bind socket with special port then recvFrom socket to get data, client's ip and port, client port are constant in one connection time, reply to that constant port
    sock <- socket AF_INET Datagram 0
    bind sock $ SockAddrInet local_port $ tupleToHostAddress local_ip

    -- as client, connect socket with remote ip and special port then send and recv with socket without port, but the client send port is constant in one connection time
    -- server recv and send both need port, client recv and send do not need port
    sockDns <- socket AF_INET Datagram 0
    connect sockDns $ SockAddrInet remote_port $ tupleToHostAddress remote_ip

    forkIO $ forever $ do
        (msg, addr) <- recvFrom sock 10240
        {- print $ decode msg -}
        {- traverse (\x -> print $ qname <$> question x) $ decode msg -}


        eitherResult :: Either DNSError [String] <- runExceptT $ do
            {- IO only run Right way -}
            q <- ExceptT ((return . decode) msg :: IO (Either DNSError DNSMessage))
            let qnames = (unpack <$>) . (qname <$>) . question $ q
            if or [isInfixOf i _y | i <- blacklist, _y <- qnames] then do
                return $ ("blacked: " <>) <$> qnames
            else do
                let qid = (identifier . header) q
                liftIO $ (fromList [(qid, addr)] <>) <$> (takeMVar searchMap) >>= putMVar searchMap >>= \x -> sendAll sockDns $ reverse msg
                return qnames
        
        case eitherResult of 
            Left x -> print eitherResult
            Right y -> do
                traverse print y
                return ()

        {- let _query = ((qname <$>) . question) <$> decode msg -}
        {- case _query of  -}
            {- Left x -> print _query -}
            {- Right y -> do -}
                {- if or [isInfixOf i _y | i <- blacklist, _y <- (unpack <$> y)] then do -}
                    {- traverse print $ ("blacked: " <>) <$> (unpack <$> y) -}
                    {- return () -}
                {- else do -}
                    {- traverse (\a -> (fmap (<> a) (takeMVar searchMap)) >>= putMVar searchMap >>= \x -> sendAll sockDns $ reverse msg) $ fmap ((\x -> fromList [(x,addr)]) . identifier . header) $ decode msg -}
                    {- print y -}
    

    forever $ do
        msg <- reverse <$> recv sockDns 10240
        {- print $ decode msg -}
        -- traverse (\a -> (putStr $ replicate 42 ' ') >> (print [(rrname x, rdata x) | x <- answer a])) $ decode msg

        let _r = decode msg
        let _r1 = fmap (\a -> [(rrname x, rdata x) | x <- answer a]) $ _r
        if _r1 /= Right [] then do
            traverse print _r1
            traverse (\x -> fmap (! x) (readMVar searchMap) >>= sendAllTo sock msg) $ fmap (identifier . header) $ _r
        else
            fmap Right (print "empty list from server")
