{-# LANGUAGE OverloadedStrings #-}
import System.Environment
import qualified Data.Map.Strict as M
import qualified Data.Text.IO as DTI
import qualified Data.Text as T
import qualified Data.List as L

list2Tuple [a,b] = (a,b)

main :: IO ()
main = do
    fileName <- getArgs
    if (L.null fileName) then
        print "it needs a file name"
    else do
        context <- DTI.readFile $ L.head fileName
        print context
        -- print . L.filter (/= "") . T.splitOn "\n" $ context
        let config = M.fromList . fmap list2Tuple . fmap (T.splitOn "=") . L.filter (/= "") . T.splitOn "\n" . T.replace "\r" "\n" . T.filter (/= ' ') $ context

        print config
        print $ config M.! "server"

-- another way is Try using openFile explicitly, so that you can hSetNewlineMode hdl universalNewlineMode before using hGetContents
-- (considering that this is the implementation of readFile https://hackage.haskell.org/package/text-1.2.4.0/docs/src/Data.Text.IO.html#readFile )

-- ./parseConf a.conf
-- a.conf
-- server=irc.freenode.net
-- port=6667
-- nick=whatever
-- autoJoinChannel = #l
-- _token =bot9
-- _chatId= 7

