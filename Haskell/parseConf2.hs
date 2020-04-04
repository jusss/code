{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE MultiWayIf #-}
import System.Environment
import Data.Map.Strict
import qualified Data.Text.IO as DTI
import Data.Text as T
import qualified Data.List as L
import Data.Either
import Data.Foldable as F

list2Tuple [a,b] = (a,b)

filterComments :: Text -> Text -> Text
filterComments commentSymbol = L.head . T.splitOn commentSymbol

filterSpaces :: Text -> Text
filterSpaces = T.filter (/= ' ')

filterNewLines :: Text -> [Text]
filterNewLines =  T.splitOn "\n" . T.replace "\r" "\n"

filterEmptyStrings :: [Text] -> [Text]
filterEmptyStrings = L.filter (/= "")

-- syntax like `a op b`, infix expression, not prefix or postfix
checkSyntax :: Text -> Text -> Either Text Text
checkSyntax op txt = if | T.isInfixOf op txt -> if | (L.length . splitWith op $ txt) == 2 -> Right txt
                                                   | otherwise -> Left txt
                        | otherwise -> Left txt

splitWith :: Text -> Text -> [Text]
splitWith x xs = L.filter (/= "") . T.splitOn x $ xs

main :: IO ()
main = do
    fileName <- getArgs
    if (L.null fileName) then
        putStrLn "it needs a config file name"
    else do
        context <- DTI.readFile $ L.head fileName
        putStrLn . T.unpack $ context
        -- print . L.filter (/= "") . T.splitOn "\n" $ context
        -- let config = fromList . fmap list2Tuple . fmap (T.splitOn "=") . L.filter (/= "") . T.splitOn "\n" . T.replace "\r" "\n" . T.filter (/= ' ') $ context
        -- let config = fromList . fmap list2Tuple . fmap (T.splitOn "=")  . filterEmptyStrings . fmap (filterComments "--") . filterNewLines . filterSpaces $ context 
        -- let config = fromList . fmap list2Tuple . fmap (T.splitOn "=")  . 
        -- r1 :: [Maybe Text]
        let r1 = fmap (checkSyntax "=") . filterEmptyStrings . fmap (filterComments "--") . filterNewLines . filterSpaces $ context 
        if | L.any isLeft r1 -> do
                putStrLn "invalid syntax: "
                putStrLn . T.unpack . fold . fmap (<> "\n") . lefts $ r1
           | otherwise -> do
                let config = fromList . fmap list2Tuple . fmap (T.splitOn "=") . rights $ r1
                let keyList = L.sort . keys $ config
                let supposeKeyList = L.sort ["server", "port", "nick", "channel", "token", "chatId", "mode"]
                if | (L.length keyList) == (L.length supposeKeyList) -> if | keyList == supposeKeyList -> do
                                                                                print config
                                                                                -- print $ config ! "server"
                                                                           | otherwise -> do 
                                                                                putStrLn "unknown parameters: "
                                                                                putStrLn . T.unpack $ foldMap (<> "\n") (keyList L.\\ supposeKeyList)
                                                                                putStrLn "missing parameters: "
                                                                                putStrLn . T.unpack $ foldMap (<> "\n") (supposeKeyList L.\\ keyList)
                                                                                
                   | (L.length keyList) > (L.length supposeKeyList) -> do 
                                                                           putStrLn "unknown parameters: "
                                                                           putStrLn . T.unpack $ foldMap (<> "\n") (keyList L.\\ supposeKeyList)
                                                                           if | L.null (supposeKeyList L.\\ keyList) -> return ()
                                                                              | otherwise -> do putStrLn "missing parameters: "
                                                                                                putStrLn . T.unpack $ foldMap (<> "\n") (supposeKeyList L.\\ keyList)
                   | otherwise -> do
                        putStrLn "missing parameters: "
                        putStrLn . T.unpack $ foldMap (<> "\n") (supposeKeyList L.\\ keyList)
                        if | L.null (keyList L.\\ supposeKeyList) -> return ()
                           | otherwise -> do putStrLn "unknown parameters: "
                                             putStrLn . T.unpack $ foldMap (<> "\n") (keyList L.\\ supposeKeyList)
                        

-- use -- as commments
-- another way is Try using openFile explicitly, so that you can hSetNewlineMode hdl universalNewlineMode before using hGetContents
-- (considering that this is the implementation of readFile https://hackage.haskell.org/package/text-1.2.4.0/docs/src/Data.Text.IO.html#readFile )

-- ./parseConf2 a.conf
-- a.conf
-- server=irc.freenode.net
-- port=6667
-- nick=whatever
-- channel = #l
-- token =bot9
-- chatId= 7
-- mode = lite
-- lite or normal

