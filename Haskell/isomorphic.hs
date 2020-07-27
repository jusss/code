f :: Maybe String -> String
f Just a = a
f Nothing = "Nothing"

g :: String -> Maybe String
g "Nothing" = Nothing
g a = Just a

f2 :: Either () a -> Maybe a
f2 Left _ = Nothing
f2 Right _ = Just _

g2 :: Maybe a -> Either () a
g2 Nothing = Left ()
g2 Just a = Right a

-- Maybe String and String are not isomorphic, f . g /= id, what if f Just "Nothing"?,   f Just "Nothing" = "Nothing", but g "Nothing" = Nothing

-- Either () a and Maybe a are isomorphic,

-- a and b are isomorphic, 
-- 1, f :: a -> b and g :: b -> a, one to one correspondence,
-- 2, f . g = g . f = id
