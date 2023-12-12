{-# LANGUAGE ScopedTypeVariables #-}
import Control.Monad (forever, liftM2)
import Network.Socket
import Network.Socket.ByteString (recv, recvFrom, sendAll, sendAllTo)
import Network.DNS.Decode (decode)
import Network.DNS.Types
import Control.Concurrent (forkIO)
import Control.Concurrent.MVar
import Data.Map.Strict hiding (empty, take, drop)
import Data.ByteString (reverse, empty, take, drop)
import Prelude hiding (reverse, take, drop)
import Data.List (or, isInfixOf, replicate)
import Data.ByteString.Char8 (unpack)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Except
import Data.Word

local_ip = (0,0,0,0)
local_port = 53
remote_ip = ()
remote_port = 0
lan_ip = (192,168,0,1)
lan_port = 53
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
    ".hdslb.",
    ".cdn20.",
    ".sina.com",
    ".weibo.",
    ".doubanio."
    ]

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
            else if member qnames qd then do
                -- change qid
                let origin_id = take 2 msg
                let altered_response = origin_id <> (drop 2 (qd ! qnames))

                liftIO $ sendAllTo sock altered_response addr
                
                let _r = decode (qd ! qnames)
                let _r1 = fmap (\a -> [(rrname x, rdata x) | x <- answer a]) $ _r

                liftIO $ print _r1


                return $ ("local: " <>) <$> qnames 

            else if or [isInfixOf i _y | i <- lan_list, _y <- qnames] then do
                liftIO $ (fromList [(qid, addr)] <>) <$> (takeMVar searchMap) >>= putMVar searchMap >>= \x -> sendAll sockDnsLan msg
                liftIO $ (fromList [(qid, qnames)] <>) <$> (takeMVar id_qnames) >>= putMVar id_qnames
                return $ ("lan: " <>) <$> qnames
            else do
                liftIO $ (fromList [(qid, addr)] <>) <$> (takeMVar searchMap) >>= putMVar searchMap >>= \x -> sendAll sockDns $ reverse msg
                liftIO $ (fromList [(qid, qnames)] <>) <$> (takeMVar id_qnames) >>= putMVar id_qnames
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
    

    forkIO $ forever $ do
        msg <- reverse <$> recv sockDns 10240
        {- print $ decode msg -}
        -- traverse (\a -> (putStr $ replicate 42 ' ') >> (print [(rrname x, rdata x) | x <- answer a])) $ decode msg

        let _r = decode msg
        let _r1 = fmap (\a -> [(rrname x, rdata x) | x <- answer a]) $ _r
        if _r1 /= Right [] then do
            traverse print _r1
            traverse (\x -> fmap (! x) (readMVar searchMap) >>= sendAllTo sock msg) $ fmap (identifier . header) $ _r


            -- filter ipv6 cache, cache ipv4 only
            print $ fmap (\a -> [rrtype x | x <- answer a]) $ _r

            -- Right [AAAA] is Right [28]
            let rrtn = fmap (\a -> [ fromTYPE $ rrtype x | x <- answer a]) $ _r
            print rrtn

            case fmap (elem (28 :: Word16)) rrtn of
                Right True -> fmap Right (print "filter ipv6 ")
                _ ->
                    traverse (\x -> fmap (! x) (readMVar id_qnames) >>= (\qnames -> (fromList [(qnames, msg)] <>) <$> (takeMVar qnames_response)) >>= putMVar qnames_response) $ fmap (identifier . header) $ _r

        else
            fmap Right (print "empty list from server")

    forever $ do
        msg <- recv sockDnsLan 10240

        let _r = decode msg
        let _r1 = fmap (\a -> [(rrname x, rdata x) | x <- answer a]) $ _r
        if _r1 /= Right [] then do
            traverse (\x -> putStr "lan server: " >> print x) _r1
            traverse (\x -> fmap (! x) (readMVar searchMap) >>= sendAllTo sock msg) $ fmap (identifier . header) $ _r

            -- filter ipv6 cache, cache ipv4 only
            print $ fmap (\a -> [rrtype x | x <- answer a]) $ _r

            -- Right [AAAA] is Right [28]
            let rrtn = fmap (\a -> [ fromTYPE $ rrtype x | x <- answer a]) $ _r
            print rrtn

            case fmap (elem (28 :: Word16)) rrtn of
                Right True -> fmap Right (print "filter ipv6 ")
                _ ->
                    traverse (\x -> fmap (! x) (readMVar id_qnames) >>= (\qnames -> (fromList [(qnames, msg)] <>) <$> (takeMVar qnames_response)) >>= putMVar qnames_response) $ fmap (identifier . header) $ _r
        else
            fmap Right (print "empty list from lan server")
