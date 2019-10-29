{-# LANGUAGE OverloadedStrings #-}
import SplitString
main = print $ splitString ":nick!~... PRIVMSG #channel : " " PRIVMSG #"