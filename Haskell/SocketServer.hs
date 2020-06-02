module SocketServer where
import Network.Socket hiding (recv)
import Network.Socket.ByteString (recv)
import Data.Text.Encoding.Error
import Data.Text.Encoding

main :: IO ()
main = do
    sock <- socket AF_INET Stream 0
    setSocketOption sock ReuseAddr 1
    bind sock . SockAddrInet 30017 $ tupleToHostAddress (0,0,0,0)
    listen sock 5
    mainLoop sock

mainLoop :: Socket -> IO ()
mainLoop sock = do
    (sockC, addr) <- accept sock
    putStr $ (show addr) <> " "
    msg <- recv sockC 1024
    print . decodeUtf8With lenientDecode $ msg
    close sockC
    mainLoop sock

