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

data Result = Result { id :: Int64, name :: Text, age :: Int64 } deriving (Show, Generic)
instance FromRow Result where
        fromRow = Result <$> field <*> field <*> field

getData :: IO [Result]
getData =  do
        conn <- connectPostgreSQL "host='localhost' port=5432 dbname=test_db user=test_user password=postgres"
        -- executeMany conn "insert into emp2 (name, age) values (?,?)" [("John",49):: (Text, Int64)]
        query_ conn "SELECT * FROM emp2" :: IO [Result]

        --mapM_ print result
        -- print result
        --return $ seq (map print result) ()

--f :: IO () -> ()
--f _ = ()

changeData :: PostData -> IO Result
changeData = \(PostData op table name age) ->
        case op of
                "select" -> do
                        conn <- connectPostgreSQL "host='localhost' port=5432 dbname=test_db user=test_user password=postgres"
                        -- executeMany conn "insert into emp2 (name, age) values (?,?)" [("John",49):: (Text, Int64)]
                        fmap Prelude.head (query_ conn "SELECT * FROM emp2" :: IO [Result])

_changeData :: PostData -> IO Result
_changeData = \x ->  do
                        conn <- connectPostgreSQL "host='localhost' port=5432 dbname=test_db user=test_user password=postgres"
                        -- executeMany conn "insert into emp2 (name, age) values (?,?)" [("John",49):: (Text, Int64)]
                        fmap Prelude.head (query_ conn "SELECT * FROM emp2" :: IO [Result])

data PostData = PostData { emp2Op :: String, emp2Table :: String, emp2Name :: String, emp2Age :: Int64 } deriving (Show, Generic)
instance ToJSON PostData
instance FromJSON PostData
instance ToJSON Result
instance FromJSON Result

main = do
        r <- getData
        -- print l
        scotty 80 $ do
                get "/" $ do
                       html . D.pack . show $ r
                post "/" $ do
                        --r <- request
                        --r <- body
                        --liftIO $ print r
                        --liftIO $ print (decode r :: Maybe PostData)
                        r <- jsonData :: ActionM PostData
                        liftIO $ print r
                        -- json $ PostData "select" "emp2" "Jesse" 52
                        -- resultList <- liftAndCatchIO $ changeData r
                        --json $ \(x:xs) -> x $ resultList
                        --liftIO $ changeData r
                        liftIO $ _changeData r >>= print
                        json =<< (liftIO $ _changeData r)
                        --liftAndCatchIO (_changeData r) >>= json
                        --json $ Result 1 "Joe" 49
                        --liftIO $ void $ fmap json $ changeData r
