import Control.Monad (forever, liftM2)
import Network.Socket
import Network.Socket.ByteString (recv, recvFrom, sendAll, sendAllTo)
import Network.DNS.Decode
import Network.DNS.Types
import Control.Concurrent (forkIO)
import Control.Concurrent.MVar
import Data.Map.Strict hiding (null)
import Data.ByteString (reverse)
import Prelude hiding (reverse, null)
import Control.Monad.IO.Class (liftIO)
import Data.List (null)
import Control.Monad.Trans.Except

local_ip = (0,0,0,0)
local_port = 0
-- remote_ip = (8,8,8,8)
remote_ip = (216,146,35,35)
remote_port = 53

main = do
    searchMap <- newMVar $ fromList [(0,SockAddrInet local_port $ tupleToHostAddress local_ip)]

    sock <- socket AF_INET Datagram 0
    bind sock $ SockAddrInet local_port $ tupleToHostAddress local_ip

    sockDns <- socket AF_INET Datagram 0
    connect sockDns $ SockAddrInet remote_port $ tupleToHostAddress remote_ip

    forkIO $ forever $ do
        (_msg, addr) <- recvFrom sock 65507
        let msg = reverse _msg
        traverse (\a -> (fmap (insert a addr) (takeMVar searchMap)) >>= putMVar searchMap >>= \x -> sendAll sockDns msg) $ fmap (identifier . header) $ decode msg
    
    forever $ do
        msg <- recv sockDns 65507
        -- print $ decode msg
        eitherResult <- runExceptT $ do
            _r <- ExceptT ((return . decode) msg :: IO (Either DNSError DNSMessage))
            let _r1 = if null (answer _r) then f authority else f answer where f y = fmap (\x -> (rrname x, rdata x)) $ y _r
            if null _r1 then do
                liftIO (putStr $ "no answer or authority: ")
                liftIO $ print _r
            else do
                liftIO $ print _r1
                liftIO $ (\x -> fmap (! x) (readMVar searchMap) >>= sendAllTo sock (reverse msg)) $ (identifier . header) _r

        case eitherResult of
            Left x -> print eitherResult
            Right y -> return ()
