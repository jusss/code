module MDNS.Config.Parse (getConfig, Config(..)) where

{-# LANGUAGE OverloadedStrings #-}

import Data.Aeson hiding (encode, decode)
import qualified Data.Aeson (encode, decode)
import Data.Aeson.Key (fromString)
import Data.Aeson.Types
import qualified Data.ByteString.Lazy as DBL
import Data.IP
import Network.Socket
import Data.Map.Strict hiding (take, drop, null)
import Network.DNS.Types
import Data.ByteString.Char8 (pack, ByteString)

compose bc ab = if (null bc) then empty else mapMaybe (bc !?) ab

convertType :: Map String [String] -> [(TYPE, ByteString)]
convertType x = [(x,y) | (x,ys) <- b, y <- ys ] where 
    b = toList $ compose (fmap pack <$> x) $ fromList [(A, "A"),(AAAA, "AAAA")]

-- data JsonConfig = JsonConfig {
        -- local_ip :: String,
        -- local_port :: Int,
        -- remote_ip :: String,
        -- remote_port :: Int,
        -- lan_ip :: String,
        -- lan_port :: Int,
        -- enable_cache :: Bool,
        -- cache_timeout :: Integer,
        -- black_list :: Map String [String],
        -- lan_list :: Map String [String]
        -- } deriving Show

data Config = Config {
        local_ip :: IP,
        local_port :: PortNumber,
        remote_ip :: IP,
        remote_port :: PortNumber,
        lan_ip :: IP,
        lan_port :: PortNumber,
        enableCache :: Bool,
        cacheTimeout :: Integer,
        blacklist :: [(TYPE, ByteString)],
        lan_list :: [(TYPE, ByteString)]
        } deriving Show

instance FromJSON Config where
    parseJSON (Object v) = Config
        <$> (read <$> (v .: (fromString "local_ip") :: Parser String) :: Parser IP)
        <*> (fromIntegral <$> (v .: (fromString "local_port") :: Parser Int) :: Parser PortNumber)
        <*> (read <$> (v .: (fromString "remote_ip") :: Parser String) :: Parser IP)
        <*> (fromIntegral <$> (v .: (fromString "remote_port") :: Parser Int) :: Parser PortNumber)
        <*> (read <$> (v .: (fromString "lan_ip") :: Parser String) :: Parser IP)
        <*> (fromIntegral <$> (v .: (fromString "lan_port") :: Parser Int) :: Parser PortNumber)
        <*> v .: (fromString "enable_cache")
        <*> v .: (fromString "cache_timeout")
        <*> (convertType <$> (v .: (fromString "black_list") :: Parser (Map String [String])))
        <*> (convertType <$> (v .: (fromString "lan_list") :: Parser (Map String [String])))


getConfig :: DBL.ByteString -> Either String Config
getConfig = eitherDecode


-- getConfig :: ByteString -> Either String Config
-- getConfig context = do
    -- r <- eitherDecode context :: Either String JsonConfig
    -- let _local_ip = read (local_ip r) :: IP
    -- let _local_port = fromIntegral $ local_port r :: PortNumber
    -- let _remote_ip = read (remote_ip r) :: IP
    -- let _remote_port = fromIntegral $ remote_port r :: PortNumber
    -- let _lan_ip = read (lan_ip r) :: IP
    -- let _lan_port = fromIntegral $ lan_port r :: PortNumber
    -- let _black_list = convertType (black_list r)
    -- let _lan_list = convertType (lan_list r)
    -- return $ Config _local_ip _local_port _remote_ip _remote_port _lan_ip _lan_port (enable_cache r) (cache_timeout r) _black_list _lan_list

