import Text.Parsec
import Text.ParserCombinators.Parsec hiding (try)
import Data.Either
import Data.Functor
import Data.Map hiding (filter)
import Data.Maybe
import qualified Control.Applicative as C

parseComment :: Parser (Maybe (String,String))
parseComment = try $ do
    spaces
    string "--"
    c <- manyTill anyChar newline
    spaces
    return Nothing

parseAssign :: Parser (Maybe (String,String))
parseAssign = try $ do
  spaces
  k <- many letter
  spaces
  char '='
  spaces
  v <- many (noneOf "\n ")
  spaces
  return $ Just (k,v)

parseInvalid :: Parser (Maybe (String, String))
parseInvalid = try $ do
    spaces
    manyTill anyChar newline
    spaces
    return Nothing

findIn :: String -> Either ParseError (Map String String) -> Maybe String
findIn key (Right m) = fromRight Nothing $ fmap (!? key) (Right m)
findIn key (Left m) = Nothing

main = do
  context <- readFile "a.conf"
  let r2 = parse (many (parseComment <|> parseAssign <|> parseInvalid)) "" context
  print r2
  let r3 = fmap (filter (/= Nothing)) r2
  if (Right [] == r3) then print "no assignment, just comments and invalid styles"
  else do
    print r3 -- Right [Just ("a","b")]
    let r9 = fmap fromList (fmap (fmap fromJust) r3)
    print r9 -- Right fromList [("a","b")]

    let result = fromRight Nothing (fmap (!? "server") r9)
    if (result == Nothing) then print "server not found"
    else print $ fromJust result

    -- another version, same as above
    let r5 = findIn "server" r9
    if (r5 == Nothing) then print "server not found" else print $ fromJust r5


  
-------------
-- a.conf
-- a = 5
-- -- test
-- b = 3
-- server = abc.net
-- port = 7000
