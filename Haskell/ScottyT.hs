{-# LANGUAGE OverloadedStrings #-}
import Network.Wai

import Network.HTTP.Types
import Network.Wai.Handler.Warp (run)
import Web.Scotty.Trans 
import Control.Monad.IO.Class
import System.Directory
import Control.Monad
import System.Environment
import Network.Wai.Parse
import qualified System.Posix.IO as SPI
import qualified Data.List as DL
import Data.Text.Lazy 
import qualified Control.Monad.Trans.State as TS

-- State in scottyT can't persist, every request create a new state

main = 
    scottyT 3000 id $ do
        get "/" (text "hello") ::  ScottyT Text IO ()
