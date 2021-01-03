import Text.Parsec hiding (try)
import Text.ParserCombinators.Parsec

-- 1. raw string " {"a":{"b":"c"}, "d":["e","f", {"h":"i"}]} "
-- because Java's type, so {"a":"b", "c":[3]} is not ok
-- 2. data type in Haskell 
-- 3. find the unit, the bottom in recursion, Nothing in Maybe a
-- 4. parseT and parsers within it are calling each other, mutual-recursion

data Json = String String 
            | Int Int
            | List [Json]
            | Map String Json deriving Show


-- main = print $ parse parseT "" "{\"a\":{\"b\":\"c\"},\"d\":[\"e\",\"f\",{\"h\":\"i\"}]}"
-- main = print $ parse parseT "" "{\"abc\":[\"c\",\"d\"],\"b\":[\"e\"]}"
-- main = print $ parse parseT "" "{\"abc\":\"c\",\"a\":\"b\"}"
-- {"reqType": 0, "perception": {"inputText": {"text": "hi"}, "inputImage": {"url": "imageUrl"}, "selfInfo": {"location": {"city": "北京", "province": "北京", "street": "信息路"}}}, "userInfo": {"apiKey": "79229c49d0014c68ab90b9282ebf7156", "userId": "360371"}}
main = do
    context <- readFile "/tmp/jsonData"
    print $ parse parseT "" context

-- parseT = parseInt <|> parseString <|> parseList <|> parseMap <|> parseUnit <|> parseUnits
parseT = parseString <|> parseList <|> parseMap <|> parseUnit <|> parseUnits

parseInt :: Parser Json
parseInt = try $ do
    v <- many digit
    return $ Int (read v)
                                   
parseString :: Parser Json         
parseString = try $ do             
    char '\"'                      
    v <- many $ noneOf ("\"")      
    char '\"'                     
    return $ String v

parseList :: Parser Json
parseList = try $ do
    char '['
    l <- sepBy parseT (string ", ")
    char ']'
    return $ List l

parseMap :: Parser Json
parseMap = try $ do
    char '{'
    char '\"'
    k <- many $ noneOf ("\"")      
    char '\"'                     
    string ": "
    v <- parseT  -- paretT will work on the rest, then return the result to v
    char '}'
    return $ Map k v
    
parseUnit :: Parser Json
parseUnit = try $ do
    char '\"'
    k <- many $ noneOf ("\"")      
    char '\"'                     
    string ": "
    v <- parseT  -- paretT will work on the rest, then return the result to v
    return $ Map k v

parseUnits :: Parser Json
parseUnits = try $ do
    char '{'
    v <- sepBy parseUnit (string ", ")
    char '}'
    return $ List v
