import Text.Parsec
import Text.ParserCombinators.Parsec
import Data.Map

parseString :: Parser (String, String)
parseString = (,) <$> (many (satisfy (== ' ')) *> (many letter) <* (many (satisfy (== ' ')))  <* (char '=')) 
                  <*> (many (satisfy (== ' ')) *> (many (noneOf "\n ")))

parseString1 :: Parser (String, String)
parseString1 = do
  many (satisfy (== ' '))
  x <- many letter
  many (satisfy (== ' '))
  char '='
  many (satisfy (== ' '))
  y <- many (noneOf "\n ") -- don't consume newline and space
  return (x,y)

-- best, parse (many parseString2) "" "server=abc\nport=6667\n"
parseString2 :: Parser (String, String)
parseString2 = do
  spaces
  x <- many letter
  spaces
  char '='
  spaces
  y <- many (noneOf "\n ") -- don't consume space and newline
  -- `space` would consume newline, letter only consume alphebet, so letter can't consume whole abc.net 
  spaces
  return (x,y)

main = do
  context <- readFile "a.conf"
  -- let r = parse (endBy parseString newline) "" context
  -- print r
  -- let r1 = parse (endBy parseString1 newline <* spaces <* eof) "" context
  -- sepBy and splitOn have the same issue, 
  -- splitOn "\n" "a\nb\n" == ["a","b",""]
  -- parse (sepBy (many (noneOf "\n")) newline) "" "server=abc\nport=6667\n"
  -- == Right ["server=abc","port=6667",""]
  -- parse (sepBy (many (noneOf "\n")) newline) "" "server=abc\nport=6667"
  -- == Right ["server=abc","port=6667"]
  -- so use endBy
  -- lines and endBy for line terminators, splitOn and sepBy for others
  -- lines "a\nb\n" == ["a","b"]

  let r2 = parse (many parseString2) "" context
  -- print r1
  print r2
  --  let r3 = (fmap fromList r2)
  --  print r3
  let r3 = fromList <$> r2
  print (Right (! "server") <*> r3)




------------------------------------------------
-- a.conf

 
--server = irc.freenode.net
--port=6667


-- nick=
--       whatever

--channel = #l
--token =bot9
--chatId= 7
--mode = lite

