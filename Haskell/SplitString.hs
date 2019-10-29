{-# LANGUAGE OverloadedStrings #-}
module SplitString where
import SplitList
import Data.ByteString 
-- main = print $ splitList [1,2] [1]

-- a = unpack ":nick!~... PRIVMSG #channel : "
-- b = unpack " PRIVMSG #"

-- main = print $ splitString ":nick!~... PRIVMSG #channel : " " PRIVMSG #"

splitString a b =
            fmap (\i -> pack i) $ splitList x y
            where
                x = unpack a
                y = unpack b
