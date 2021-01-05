import Text.Parsec hiding (try)
import Text.ParserCombinators.Parsec
-- import Text.Parser.Token
import Data.Char
import Data.List
import Data.Either
-- cabal install parsers

-- 1. raw string " {"a":{"b":"c"}, "d":["e","f", {"h":"i"}]} "
-- because Java's type, so {"a":"b", "c":[3]} is not ok
-- 2. data type in Haskell 
-- 3. find the unit, the bottom in recursion, Nothing in Maybe a
-- 4. parseT and parsers within it are calling each other, mutual-recursion

data Json = String String 
            | Int Integer
            | List [Json]
            | Map String Json deriving Show

-- main = print $ parse parseT "" "{\"a\":{\"b\":\"c\"},\"d\":[\"e\",\"f\",{\"h\":\"i\"}]}"
-- main = print $ parse parseT "" "{\"abc\":[\"c\",\"d\"],\"b\":[\"e\"]}"
-- main = print $ parse parseT "" "{\"abc\":\"c\",\"a\":\"b\"}"
-- {"reqType": 0, "perception": {"inputText": {"text": "hi"}, "inputImage": {"url": "imageUrl"}, "selfInfo": {"location": {"city": "北京", "province": "北京", "street": "信息路"}}}, "userInfo": {"apiKey": "79229c49d0014c68ab90b9282ebf7156", "userId": "360371"}}

main = do
    context <- readFile "/tmp/jsonData"
    print $ (Right (parse parseT "")) <*> (deleteSpaces  context)

parseT = parseInt <|> parseString <|> parseList <|> parseMap <|> parseUnit <|> parseUnits

parseInt :: Parser Json
parseInt = try $ do
    l <- many1 digit -- weird, many digit won't work, it cause Prelude.read: no parse, but many1 digit works
    return $ Int (read l)

-- parseInt :: Parser Json
-- parseInt = try $ do
--     l <- decimal
--     return $ Int l
                                   
parseString :: Parser Json         
parseString = try $ do             
    char '\"'                      
    v <- many $ noneOf ("\"")      
    char '\"'                     
    return $ String v

parseList :: Parser Json
parseList = try $ do
    char '['
    l <- sepBy parseT (char ',')
    char ']'
    return $ List l

parseMap :: Parser Json
parseMap = try $ do
    char '{'
    char '\"'
    k <- many $ noneOf ("\"")      
    char '\"'                     
    char ':'
    v <- parseT  -- paretT will work on the rest, then return the result to v
    char '}'
    return $ Map k v
    
parseUnit :: Parser Json
parseUnit = try $ do
    char '\"'
    k <- many $ noneOf ("\"")      
    char '\"'                     
    char ':'
    v <- parseT  -- paretT will work on the rest, then return the result to v
    return $ Map k v

parseUnits :: Parser Json
parseUnits = try $ do
    char '{'
    v <- sepBy parseUnit (char ',')
    char '}'
    return $ List v


removeSpaces :: String -> String
removeSpaces x = filter (not . isSpace) x

removeEmptyString :: [String] -> [String]
removeEmptyString x = filter ((/= 0) . length) x

removeSpacesInString :: Parser [String]
removeSpacesInString = try $ do             
    p <- many $ noneOf ("\"")      
    char '\"'                      
    v <- many $ noneOf ("\"")      
    char '\"'                     
    s <- many $ noneOf ("\"")      
    return $ [(removeSpaces p), ("\"" <> v <> "\""), (removeSpaces s)]

deleteSpaces :: String -> Either ParseError String
deleteSpaces x = (Right $ foldl1 (<>)) <*> result2 where
                        result2 = (Right $ foldl1 (<>))  <*> result
                        result = (Right (removeEmptyString <$>))  <*>  (parse (many removeSpacesInString) ""  x)

