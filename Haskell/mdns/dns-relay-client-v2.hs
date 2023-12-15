{-# LANGUAGE ScopedTypeVariables #-}
import Control.Monad (forever, liftM2)
import Network.Socket
import Network.Socket.ByteString (recv, recvFrom, sendAll, sendAllTo)
import Network.DNS.Decode (decode)
import Network.DNS.Types
import Control.Concurrent (forkIO)
import Control.Concurrent.MVar
import Data.Map.Strict hiding (empty, take, drop, null)
import Data.ByteString (reverse, empty, take, drop, ByteString)
import Prelude hiding (reverse, take, drop)
import Data.List (or, isInfixOf, replicate, null, last)
import Data.ByteString.Char8 (unpack)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Except
import Data.Word

local_ip = (0,0,0,0)
local_port = 53
remote_ip = ()
remote_port = 0
-- lan_ip = ()
lan_ip = (114,114,114,114)
lan_port = 53

-- enableCache = True
enableCache = True

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
    ".1bbpaqq.com.",
    ".lmabc001.com.",
    ".1kfnsra.com.",
    ".xmchwl.com",
    ".1mxabnt.com.",
    "liangbingliang2.cn.",
    ".1bbpaqq.com.",
    "detectportal.firefox.com",
    "prod.cloudops.mozgcp.net",
    "push.services.mozilla.com",
    "prod.mozaws.net",
    "firefox.settings.services.mozilla.com",
    ".shdndn2.cn"]

-- lan_list for lan dns
lan_list = [
    "zhihu.com",
    "baidu.com",
    "91mjw.",
    ".91mjw.",
    ".bytecdntp.com.",
    "91pic.org",
    ".douban.",
    ".qq.com",
    ".zhimg.com.",
    ".163.com",
    ".51job.com",
    ".jd.com",
    ".jingdong.com",
    ".jdpay.com",
    ".jdcloud.com",
    ".360buy.com",
    ".360buyimg.com",
    ".bilibili.com",
    ".bilicd1.",
    ".bilivideo.",
    "bdstatic.com",
    "baidu",
    "bcebos.com",
    ".hdslb.",
    ".cdn20.",
    ".gov.cn",
    "dict.cn",
    ".cn.",
    ".alicdn.",
    "commonwealthproficient.com.",
    "tendacn.com.",
    "weibo.",
    ".sina.com",
    ".weibo.",
    ".doubanio."
    ]

recvMsg :: String -> (ByteString -> ByteString) -> Socket -> Socket -> MVar (Map Identifier SockAddr) -> MVar (Map Identifier [String]) -> MVar (Map [String] ByteString) -> IO ()
recvMsg prompt handle recvSock sock searchMap id_qnames qnames_response =
    forever $ do
        msg <- handle <$> recv recvSock 10240
        eitherResult <- runExceptT $ do
            {- IO only run Right way -}
            _r <- ExceptT ((return . decode) msg :: IO (Either DNSError DNSMessage))
            let _r1 = fmap (\x -> (rrname x, rdata x)) $ answer _r
            if null _r1 then
                liftIO (print $ "empty list from server of " <> prompt)
            else do
                liftIO $ traverse (\x -> putStr (prompt <> " server: ") >> print x) _r1
                liftIO $ (\x -> fmap (! x) (readMVar searchMap) >>= sendAllTo sock msg) $ (identifier . header) $ _r

                if enableCache then do
                    -- filter ipv6, cache ipv4 only, and the last response can not be CNAME 5 or only be A 1, Right [AAAA] is Right [TYPE 28], pattern synonym
                    let rrts = fmap rrtype $ answer _r
                    -- liftIO $ print rrts
    
                    if AAAA `elem` rrts then
                        -- liftIO (print "filter ipv6 ")
                        return ()
                    else if (last rrts) == CNAME then
                        -- liftIO (print "filter CNAME")
                        return ()
                    else
                        liftIO $ (\x -> fmap (! x) (readMVar id_qnames) >>= (\qnames -> (insert qnames msg) <$> (takeMVar qnames_response)) >>= putMVar qnames_response) $ (identifier . header) $ _r
                else return ()

        case eitherResult of 
            Left x -> print eitherResult
            Right y -> return ()

main = do
    searchMap <- newMVar $ fromList [(0,SockAddrInet local_port $ tupleToHostAddress local_ip)]
    id_qnames <- newMVar $ fromList [(0,[""])]
    qnames_response <- newMVar $ fromList [([""], empty)]

    -- as server, bind socket with special port then recvFrom socket to get data, client's ip and port, client port are constant in one connection time, reply to that constant port
    sock <- socket AF_INET Datagram 0
    bind sock $ SockAddrInet local_port $ tupleToHostAddress local_ip

    -- as client, connect socket with remote ip and special port then send and recv with socket without port, but the client send port is constant in one connection time
    -- server recv and send both need port, client recv and send do not need port
    sockDns <- socket AF_INET Datagram 0
    connect sockDns $ SockAddrInet remote_port $ tupleToHostAddress remote_ip

    sockDnsLan <- socket AF_INET Datagram 0
    connect sockDnsLan $ SockAddrInet lan_port $ tupleToHostAddress lan_ip

    forkIO $ forever $ do
        (msg, addr) <- recvFrom sock 10240
        {- print $ decode msg -}
        {- traverse (\x -> print $ qname <$> question x) $ decode msg -}

        eitherResult :: Either DNSError [String] <- runExceptT $ do
            {- IO only run Right way -}
            q <- ExceptT ((return . decode) msg :: IO (Either DNSError DNSMessage))
            let qnames = (unpack <$>) . (qname <$>) . question $ q
            let qid = (identifier . header) q
            qd <- liftIO $ readMVar qnames_response
            if or [isInfixOf i _y | i <- blacklist, _y <- qnames] then do
                return $ ("blacked: " <>) <$> qnames
            else if (member qnames qd) && enableCache  then do
                -- change qid
                let altered_response = (take 2 msg) <> (drop 2 (qd ! qnames))
                liftIO $ sendAllTo sock altered_response addr
                cacheResponse <- ExceptT ((return . decode) (qd ! qnames) :: IO (Either DNSError DNSMessage))
                let _r1 = fmap (\x -> (rrname x, rdata x)) $ answer cacheResponse
                liftIO $ traverse print (("cache: " <>) <$> qnames)
                liftIO $ print _r1
                return []

            else if or [isInfixOf i _y | i <- lan_list, _y <- qnames] then do
                liftIO $ (insert qid addr) <$> (takeMVar searchMap) >>= putMVar searchMap >>= \x -> sendAll sockDnsLan msg
                liftIO $ (insert qid qnames) <$> (takeMVar id_qnames) >>= putMVar id_qnames
                return $ ("lan: " <>) <$> qnames
            else do
                liftIO $ (insert qid addr) <$> (takeMVar searchMap) >>= putMVar searchMap >>= \x -> sendAll sockDns $ reverse msg
                liftIO $ (insert qid qnames) <$> (takeMVar id_qnames) >>= putMVar id_qnames
                return $ ("remote: " <>) <$> qnames
        
        case eitherResult of 
            Left x -> print eitherResult
            Right y -> do
                traverse print y
                return ()

    forkIO $ recvMsg "remote" reverse sockDns sock searchMap id_qnames qnames_response
    recvMsg "lan" id sockDnsLan sock searchMap id_qnames qnames_response
