{-# LANGUAGE ScopedTypeVariables #-}
import Control.Monad (forever, liftM2)
import Network.Socket
import Network.Socket.ByteString (recv, recvFrom, sendAll, sendAllTo)
import Network.DNS.Decode (decode)
import Network.DNS.Encode (encode)
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
import Data.Tuple (fst)
import Data.IP.Internal

-- this can run as a LAN dns relay server for other devices like iPad or Android Phone for filter ad

local_ip = (0,0,0,0)
local_port = 53
remote_ip = ()
remote_port = 0
lan_ip = (114,114,114,114)
lan_port = 53

enableCache = True
-- enableCache = False

blacklist = [
    ".cnzz.com",
    "hm.baidu.com",
    ".dlrtz.com",
    "whweitkeji.com",
    ".0efghij.com",
    ".shuyu2001.cn",
    "2wgolxk.com",
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
    ".2dctkld.com",
    ".xmchwl.com",
    ".1mxabnt.com.",
    "liangbingliang2.cn.",
    ".1bbpaqq.com.",
    "detectportal.firefox.com",
    "ssl.google-analytics.com",
    "crpo.baidu.com",
    "erebor.douban.com",
    "ad.doubanio.com",
    ".in-addr.arpa.",
    "tendawifi.com",
    ".zhimg.com.",
    -- "prod.cloudops.mozgcp.net",
    -- "push.services.mozilla.com",
    -- "prod.mozaws.net",
    -- "firefox.settings.services.mozilla.com",
    ".shdndn2.cn"]

-- lan_list for lan dns
lan_list = [
    ".bytecdntp.com.",
    ".qq.com",
    ".zhimg.com.",
    ".163.com",
    ".jd.com",
    ".jingdong.com",
    ".jdpay.com",
    ".jdcloud.com",
    ".360buy.com",
    ".51.la.",
    ".360buyimg.com",
    ".bilibili.com",
    ".bilicd1.",
    ".bilivideo.",
    "bdstatic.com",
    "bcebos.com",
    ".hdslb.",
    ".cdn20.",
    ".cn.",
    "alicdn",
    "commonwealthproficient.com.",
    "tendacn.com.",
    ".sina.com",
    "zhihu",
    "baidu",
    "51job",
    "91mjw",
    "91pic",
    "weibo",
    "youdao",
    "douban"
    ]

recvMsg :: String -> (ByteString -> ByteString) -> Socket -> Socket -> MVar (Map Identifier SockAddr) -> MVar (Map [String] ByteString) -> IO ()
recvMsg prompt handle recvSock sock id_addr qnames_response =
    forever $ do
        msg <- handle <$> recv recvSock 65507
        eitherResult <- runExceptT $ do
            {- IO only run Right way -}
            _r <- ExceptT ((return . decode) msg :: IO (Either DNSError DNSMessage))
            -- SOA type has no anwser but authority, RCode NXDomain
            let _r1 = if null (answer _r) then f authority else f answer where f y = fmap (\x -> (unpack $ rrname x, rdata x)) $ y _r
            if null _r1 then do
                liftIO (putStr $ "no anwser or authority from server of " <> prompt)
                liftIO $ print _r
            else do
                liftIO $ putStr (prompt <> " server: ")
                liftIO $ print _r1
                liftIO $ (\x -> fmap (! x) (readMVar id_addr) >>= sendAllTo sock msg) $ (identifier . header) $ _r

                if enableCache then do
                    -- filter ipv6, cache ipv4 only, and the last response can not be CNAME 5 or only be A 1, Right [AAAA] is Right [TYPE 28], pattern synonym
                    let rrts = if null (answer _r) then f authority else f answer where f y = fmap rrtype $ y _r
                    -- liftIO $ print rrts
    
                    if AAAA `elem` rrts then
                        -- liftIO (print "filter ipv6 ")
                        return ()
                    else if (last rrts) == CNAME then
                        -- liftIO (print "filter CNAME")
                        return ()
                    else
                        liftIO $ (insert [(fst $ head _r1)] msg) <$> (takeMVar qnames_response) >>= putMVar qnames_response
                else return ()

        case eitherResult of 
            Left x -> print eitherResult
            Right y -> return ()

main = do
    id_addr <- newMVar $ fromList [(0,SockAddrInet local_port $ tupleToHostAddress local_ip)]
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
        (msg, addr) <- recvFrom sock 65507
        {- print $ decode msg -}
        {- traverse (\x -> print $ qname <$> question x) $ decode msg -}

        eitherResult :: Either DNSError () <- runExceptT $ do
            {- IO only run Right way -}
            q <- ExceptT ((return . decode) msg :: IO (Either DNSError DNSMessage))
            let qnames = (unpack <$>) . (qname <$>) . question $ q
            let qid = (identifier . header) q
            qd <- liftIO $ readMVar qnames_response
            if or [isInfixOf i _y | i <- blacklist, _y <- qnames] then do
                liftIO $ putStr "blacked: "
                liftIO $ print qnames

                -- liftIO $ traverse (\x -> putStr "fake response: " >> print x >> sendAllTo sock (encode x) addr) $ fmap (\qu -> makeResponse qid qu $ anw qu) $ question q where
                    -- anw qu = [ResourceRecord (qname qu) (qtype qu) (1 :: Word16) (21 :: Word32) (RD_A (read "127.0.0.1" :: IPv4))]

                let fake_responses = fmap (\qu -> makeResponse qid qu $ anw qu) $ question q where
                    anw qu = [ResourceRecord (qname qu) (qtype qu) (1 :: Word16) (86400 :: Word32) (RD_A (read "127.0.0.1" :: IPv4))]
                liftIO $ putStr "fake response: " >> print fake_responses
                liftIO $ traverse (\fr -> sendAllTo sock fr addr) (encode <$> fake_responses)
                return ()

            else if (member qnames qd) && enableCache  then do
                let _response = qd ! qnames
                cacheResponse <- ExceptT ((return . decode) _response :: IO (Either DNSError DNSMessage))
                -- let _r1 = fmap (\x -> (rrname x, rdata x)) $ answer cacheResponse
                let _r1 = if null (answer cacheResponse) then f authority else f answer where f y = fmap (\x -> (unpack $ rrname x, rdata x)) $ y cacheResponse
                if null _r1 then do
                    liftIO (putStr $ "cache no answer or authority: ")
                    liftIO $ print qnames
                    liftIO $ print cacheResponse

                    if or [isInfixOf i _y | i <- lan_list, _y <- qnames] then do
                        liftIO $ (insert qid addr) <$> (takeMVar id_addr) >>= putMVar id_addr >>= \x -> sendAll sockDnsLan msg
                        liftIO $ putStr "lan: "
                        liftIO $ print qnames
                    else do
                        liftIO $ (insert qid addr) <$> (takeMVar id_addr) >>= putMVar id_addr >>= \x -> sendAll sockDns $ reverse msg
                        liftIO $ putStr "remote: "
                        liftIO $ print qnames

                else do
                    -- change qid
                    -- let altered_response = (take 2 msg) <> (drop 2 _response)

                    let altered_response = encode $ alterIdentifier q cacheResponse where
                        alterIdentifier m r = r { header = (header r) {identifier = identifier $ header m} }

                    liftIO $ sendAllTo sock altered_response addr
                    liftIO $ putStr "cache: "
                    liftIO $ print qnames
                    liftIO $ putStr "cache server: "
                    liftIO $ print _r1

            else if or [isInfixOf i _y | i <- lan_list, _y <- qnames] then do
                liftIO $ (insert qid addr) <$> (takeMVar id_addr) >>= putMVar id_addr >>= \x -> sendAll sockDnsLan msg
                liftIO $ putStr "lan: "
                liftIO $ print qnames
            else do
                liftIO $ (insert qid addr) <$> (takeMVar id_addr) >>= putMVar id_addr >>= \x -> sendAll sockDns $ reverse msg
                liftIO $ putStr "remote: "
                liftIO $ print qnames
        
        case eitherResult of 
            Left x -> print eitherResult
            Right y -> do
                return ()

    forkIO $ recvMsg "remote" reverse sockDns sock id_addr qnames_response
    recvMsg "lan" id sockDnsLan sock id_addr qnames_response
