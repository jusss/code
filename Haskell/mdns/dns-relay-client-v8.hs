{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE RecordWildCards #-}
import Control.Monad (forever, liftM2, when)
import Network.Socket
import Network.Socket.ByteString (recv, recvFrom, sendAll, sendAllTo)
import Network.DNS.Decode (decode)
import Network.DNS.Encode (encode)
import Network.DNS.Types
import Control.Concurrent (forkIO)
import Control.Concurrent.MVar
import Data.Map.Strict hiding (empty, take, drop, null)
import Data.ByteString (reverse, empty, take, drop, ByteString, isInfixOf)
import Prelude hiding (reverse, take, drop)
import Data.List (or, replicate, null, last)
import Data.ByteString.Char8 (pack, unpack)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Except
import Data.Word
import Data.Tuple (fst)
import Data.IP.Internal
import Control.Concurrent.Thread.Delay (delay)
import System.Environment (getArgs)
import qualified Data.ByteString.Lazy as DBL
import Data.IP
import Data.Either (fromRight)
import MDNS.Config.Parse (getConfig, Config(..))

recvFromRemote :: String -> (ByteString -> ByteString) -> Socket -> Socket -> MVar (Map Identifier SockAddr) -> MVar (Map (TYPE, ByteString) ByteString) -> Bool -> IO ()
recvFromRemote prompt handle recvSock sock id_addr qnames_response enableCache = do
        msg <- handle <$> recv recvSock 65507
        eitherResult <- runExceptT $ do
            {- IO only run Right way -}
            _r <- ExceptT ((return . decode) msg :: IO (Either DNSError DNSMessage))
            -- SOA type has no anwser but authority, RCode NXDomain, NXDomain mean domain do not exist, no anwser only authority
            let _r1 :: [((TYPE,Domain),RData)] = if null (answer _r) then f authority else f answer where f y = fmap (\x -> ((rrtype x, rrname x), rdata x)) $ y _r
            if null _r1 then do
                liftIO $ (putStr $ "no anwser or authority from server of " <> prompt) >> print _r
            else do
                liftIO $ putStr (prompt <> " server: ") >> print _r1
                -- liftIO $ (\x -> fmap (! x) (readMVar id_addr) >>= sendAllTo sock msg) $ (identifier . header) $ _r
                let _id = (identifier . header) $ _r
                _id_addr <- liftIO $ readMVar id_addr
                when (member _id _id_addr) $ liftIO $ sendAllTo sock msg (_id_addr ! _id)

                when enableCache do
                    liftIO $ traverse (\x -> insert (fst x) msg <$> (takeMVar qnames_response) >>= putMVar qnames_response) _r1
                    return ()

        case eitherResult of 
            Left x -> print eitherResult
            Right y -> return ()

recvFromLocal :: Socket -> Socket -> Socket -> [(TYPE, ByteString)] -> Bool -> [(TYPE, ByteString)] -> MVar (Map Identifier SockAddr) -> MVar (Map (TYPE, ByteString) ByteString) -> IO ()
recvFromLocal sock sockDnsLan sockDns blacklist enableCache lan_list id_addr qnames_response = do
    (msg, addr) <- recvFrom sock 65507
    {- print $ decode msg -}
    {- traverse (\x -> print $ qname <$> question x) $ decode msg -}

    eitherResult :: Either DNSError () <- runExceptT $ do
        {- IO only run Right way -}
        q <- ExceptT ((return . decode) msg :: IO (Either DNSError DNSMessage))
        let qnames :: [(TYPE, ByteString)] = (\x -> (qtype x, qname x)) <$> question q
        let qid = (identifier . header) q
        qd <- liftIO $ readMVar qnames_response
        if or [(fst i == fst _y) && isInfixOf (snd i) (snd _y) | i <- blacklist, _y <- qnames] then do
            liftIO $ putStr "blacked: "
            liftIO $ print qnames

            -- liftIO $ traverse (\x -> putStr "fake response: " >> print x >> sendAllTo sock (encode x) addr) $ fmap (\qu -> makeResponse qid qu $ anw qu) $ question q where
                -- anw qu = [ResourceRecord (qname qu) (qtype qu) (1 :: Word16) (21 :: Word32) (RD_A (read "127.0.0.1" :: IPv4))]

            let fake_responses = fmap (\qu -> makeResponse qid qu $ anw qu) $ question q where
                anw qu = case qtype qu of
                    A -> [ResourceRecord (qname qu) (qtype qu) (1 :: Word16) (86400 :: Word32) (RD_A (read "127.0.0.1" :: IPv4))]
                    AAAA -> [ResourceRecord (qname qu) (qtype qu) (1 :: Word16) (86400 :: Word32) (RD_AAAA (read "::1" :: IPv6))]

            liftIO $ putStr "fake response: " >> print fake_responses
            liftIO $ traverse (\fr -> sendAllTo sock fr addr) (encode <$> fake_responses)
            return ()

        else if (member (head qnames) qd) && enableCache  then do
            let _response = qd ! (head qnames)
            cacheResponse <- ExceptT ((return . decode) _response :: IO (Either DNSError DNSMessage))
            -- let _r1 = fmap (\x -> (rrname x, rdata x)) $ answer cacheResponse
            let _r1 = if null (answer cacheResponse) then f authority else f answer where f y = fmap (\x -> ((rrtype x, rrname x), rdata x)) $ y cacheResponse
            if null _r1 then do
                liftIO $ (putStr $ "cache no answer or authority: ") >> print qnames >> print cacheResponse

                if or [(fst i == fst _y) && isInfixOf (snd i) (snd _y) | i <- lan_list, _y <- qnames] then do
                    liftIO $ (insert qid addr) <$> (takeMVar id_addr) >>= putMVar id_addr >>= \x -> sendAll sockDnsLan msg
                    liftIO $ putStr "lan: " >> print qnames
                else do
                    liftIO $ (insert qid addr) <$> (takeMVar id_addr) >>= putMVar id_addr >>= \x -> sendAll sockDns $ reverse msg
                    liftIO $ putStr "remote: " >> print qnames

            else do
                -- change qid
                let altered_response = encode $ alterIdentifier q cacheResponse where
                    alterIdentifier m r = r { header = (header r) {identifier = identifier $ header m} }

                liftIO $ sendAllTo sock altered_response addr
                liftIO $ putStr "cache: " >> print qnames >> putStr "cache server: " >> print _r1

        else if or [(fst i == fst _y) && isInfixOf (snd i) (snd _y) | i <- lan_list, _y <- qnames] then do
            liftIO $ (insert qid addr) <$> (takeMVar id_addr) >>= putMVar id_addr >> sendAll sockDnsLan msg
            liftIO $ putStr "lan: " >> print qnames
        else do
            liftIO $ (insert qid addr) <$> (takeMVar id_addr) >>= putMVar id_addr >> (sendAll sockDns $ reverse msg)
            liftIO $ putStr "remote: " >> print qnames
    
    case eitherResult of 
        Left x -> print eitherResult
        Right y -> return ()

-- avoid lots of liftIO,
-- 1. mtl instead of transformers
-- 2. all IO in one function, liftIO one function
-- 3. all IO in one do notaion, liftIO one do notation

main = do
    fileName <- getArgs
    if (null fileName) then
        putStrLn "it needs a config file"
    else do
        context <- DBL.readFile $ head fileName
        v :: Either String () <- runExceptT $ do
        -- runExceptT $ do
            config <- ExceptT $ ((return . getConfig) context :: IO (Either String Config))

            -- liftIO $ f config where
                -- f Config{..} = do
                    -- print Config{..}
                    -- the 'where' section terminates the declaration of 'main', 'where' can only attach to declarations, not expressions
            
            liftIO $ do 
                let Config{..} = config
        
                id_addr <- newMVar $ fromList [(0,toSockAddr (local_ip, local_port))]
                qnames_response <- newMVar $ fromList [((A, ""), empty)]
            
                -- as server, bind socket with special port then recvFrom socket to get data, client's ip and port, client port are constant in one connection time, reply to that constant port
                sock <- socket AF_INET Datagram 0
                -- bind sock $ SockAddrInet local_port $ tupleToHostAddress local_ip
                bind sock $ toSockAddr (local_ip, local_port)
            
                -- as client, connect socket with remote ip and special port then send and recv with socket without port, but the client send port is constant in one connection time
                -- server recv and send both need port, client recv and send do not need port
                sockDns <- socket AF_INET Datagram 0
                -- connect sockDns $ SockAddrInet remote_port $ tupleToHostAddress remote_ip
                connect sockDns $ toSockAddr (remote_ip, remote_port)
                
                sockDnsLan <- socket AF_INET Datagram 0
                -- connect sockDnsLan $ SockAddrInet lan_port $ tupleToHostAddress lan_ip
                connect sockDnsLan $ toSockAddr (lan_ip, lan_port)
            
                forkIO $ forever $ recvFromLocal sock sockDnsLan sockDns blacklist enableCache lan_list id_addr qnames_response
                
                when (enableCache && cacheTimeout > 600000000) do
                    forkIO $ forever do
                        delay cacheTimeout >> print "clean cache"
                        takeMVar id_addr >> (putMVar id_addr $ fromList [(0,toSockAddr (local_ip, local_port))])
                        takeMVar qnames_response >> (putMVar qnames_response $ fromList [((A,""), empty)])
                    return ()
                
                forkIO $ forever $ recvFromRemote "remote" reverse sockDns sock id_addr qnames_response enableCache
                forever $ recvFromRemote "lan" id sockDnsLan sock id_addr qnames_response enableCache

        -- return ()
        case v of 
            Left x -> print v
            Right y -> return ()
