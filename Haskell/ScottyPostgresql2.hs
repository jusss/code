{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

import Database.PostgreSQL.Simple
import Database.PostgreSQL.Simple.FromRow
import Data.Int
import Web.Scotty
import Data.Text.Internal.Lazy as DL
import Data.Text.Lazy as D
import Control.Monad.IO.Class
import Data.Aeson (FromJSON, ToJSON, encode, decode)
import GHC.Generics
import Control.Monad (void)

-- table dialog_update
data DialogUpdate = DialogUpdate { updateVersion :: Text, updateAddress :: Text } deriving (Show, Generic)

-- table post_data
data PostData = PostData { deviceId :: Text, updateTime :: Text } deriving (Show, Generic)

instance FromRow DialogUpdate where
        fromRow = DialogUpdate <$> field <*> field
instance FromRow PostData where
        fromRow = PostData <$> field <*> field

instance ToJSON PostData
instance FromJSON PostData
instance ToJSON DialogUpdate
instance FromJSON DialogUpdate

getDialogUpdate :: IO DialogUpdate
getDialogUpdate = do
        conn <- connectPostgreSQL "host='localhost' port=5432 dbname=test_db user=test_user password=postgres"
        l <- query_ conn "SELECT * FROM dialog_update" :: IO [DialogUpdate]
        return $ Prelude.head l

insertPostData :: PostData -> IO Int64
insertPostData = \(PostData i t) -> do
        conn <- connectPostgreSQL "host='localhost' port=5432 dbname=test_db user=test_user password=postgres"
        executeMany conn "insert into post_data (device_id, update_time) values (?,?)" [(i,t):: (Text, Text)]

main = scotty 80 $ do
        get "/" $ do
                html . updateVersion =<< liftIO getDialogUpdate
        post "/" $ do
                r <- jsonData :: ActionM PostData
                liftIO $ print r
                liftIO $ insertPostData r
                liftIO getDialogUpdate >>= json



>>> import requests
>>> url='http://net/'
>>> m={'deviceId':'a06', 'updateTime':'20191115'}
>>> g=requests.post(url,json=m)
>>> g.content
'{"updateAddress":"address","updateVersion":"20191115"}'
>>>
