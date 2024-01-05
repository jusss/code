{-# LANGUAGE OverloadedStrings #-}

import qualified Data.ByteString as D
import qualified Data.ByteString.Char8 as DBC


tokenise x y = h : if D.null t then [] else tokenise x (D.drop (D.length x) t)
    where (h,t) = D.breakSubstring x y

main = print $ fmap DBC.unpack $ tokenise "d" "abc"
