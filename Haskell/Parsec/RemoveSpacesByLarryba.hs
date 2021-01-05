import Text.Parsec
import Text.Parsec.String

main :: IO ()
main = do
  case parse parserListLiteral "" "[\"a\", \"b e\"]" of
    Left err -> print err
    Right x  -> print x

parserChar :: Parser Char
parserChar = noneOf "\""

parserString :: Parser String
parserString = many1 parserChar

parserStringLiteral :: Parser String
parserStringLiteral = between (char '"') (char '"') parserString

parserListLiteral :: Parser [String]
parserListLiteral = do
  char '['
  xs <- (spaces *> parserStringLiteral <* spaces) `sepBy` char ','
  char ']'
  return xs


-- import Text.Parsec
-- import Text.Parsec.String
-- 
-- main :: IO ()
-- main = do
-- --   case parse parserListLiteral "" "[\"a\", \"b e\"]" of
--   case parse parserListLiteral "" "{\"a\": \"b e\" }" of
--     Left err -> print err
--     Right x  -> print x
-- 
-- parserChar :: Parser Char
-- parserChar = noneOf "\""
-- 
-- parserString :: Parser String
-- parserString = many1 parserChar
-- 
-- parserStringLiteral :: Parser String
-- parserStringLiteral = between (char '"') (char '"') parserString
-- 
-- parserListLiteral :: Parser [String]
-- parserListLiteral = do
--   try (char '[' <|> char '{')
--   xs <- (spaces *> parserStringLiteral <* spaces) `sepBy` (try (char ',' <|> char ':'))
--   try (char ']' <|> char '}')
--   return xs

-- use <|> in this to match [ or { is meaningless, should be parse[ and parse{ two parsers, then parserT = parse[ <|> parse{, special action to special result
