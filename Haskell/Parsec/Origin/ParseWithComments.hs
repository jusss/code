import Text.Parsec
import Text.ParserCombinators.Parsec hiding (try)
import Data.Either
import Data.Functor
import Data.Map hiding (filter)
import Data.Maybe
import qualified Control.Applicative as C

parseComment :: Parser (Maybe (String,String))
parseComment = do
    spaces
    string "--"
    c <- manyTill anyChar newline
    return Nothing

parseAssign :: Parser (Maybe (String,String))
parseAssign = do
  spaces
  k <- many letter
  spaces
  char '='
  spaces
  v <- many (noneOf "\n ")
  spaces
  return (Just (k,v))

main = do
  context <- readFile "a.conf"
  let r2 = parse (many (try parseComment <|> parseAssign)) "" context
  print r2
  let r3 = fmap (filter (/= Nothing)) r2
  print r3 -- Right [Just ("a","b")]
  let r9 = fmap fromList (fmap (fmap fromJust) r3)
  print r9
  print (fmap (! "server") r9) -- Right "abc.net"
  
-------------
-- a.conf
-- a = 5
-- -- test
-- b = 3
-- server = abc.net
-- port = 7000

