import Text.Parsec hiding (try)
import Text.ParserCombinators.Parsec
-- import Text.Parser.Token
import Data.Char
import Data.List
import Data.Either

data Json = String String 
            | Int Integer
            | List [Json]
            | Map String Json deriving Show

main = do
    context <- readFile "/tmp/jsonData"
    print $ (Right (parse parseT "")) <*> (deleteSpaces  context)

parseT = parseInt <|> parseString <|> parseList <|> parseMap <|> parseUnit <|> parseUnits

parseInt :: Parser Json
parseInt = try $ do
    l <- many1 digit 
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
    v <- parseT  
    char '}'
    return $ Map k v
    
parseUnit :: Parser Json
parseUnit = try $ do
    char '\"'
    k <- many $ noneOf ("\"")      
    char '\"'                     
    char ':'
    v <- parseT 
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
-----------------------------------------------------------------------------------------
-- /tmp/jsonData
-- {"reqType": 0, "perception": {"inputText": {"text": "hi"}, "inputImage": {"url": "imageUrl"}, "selfInfo": {"location": {"city": "北京", "province": "北京", "street": "信息路"}}}, "userInfo": {"apiKey": "79229c49d0014c68ab90b9282ebf7156", "userId": "360371"}}
-------------------------------------------------------------------------------------------------
-- Right (Right (List [Map "reqType" (Int 0),Map "perception" (List [Map "inputText" (Map "text" (String "hi")),Map "inputImage" (Map "url" (String "imageUrl")),Map "selfInfo" (Map "location" (List [Map "city" (String "\21271\20140"),Map "province" (String "\21271\20140"),Map "street" (String "\20449\24687\36335")]))]),Map "userInfo" (List [Map "apiKey" (String "79229c49d0014c68ab90b9282ebf7156"),Map "userId" (String "360371")])]))
