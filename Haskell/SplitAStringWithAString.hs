{-# LANGUAGE OverloadedStrings #-}
import SplitAlistWithAlist
import Data.ByteString

o = unpack ":nick!~... PRIVMSG #channel : "
a = unpack " PRIVMSG #"

main = print $ fmap (\i -> pack i) $ splitListWithList o a
