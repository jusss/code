import Text.Parsec hiding (try)
import Text.ParserCombinators.Parsec

-- 1. raw string " {"a":{"b":"c"}, "d":["e","f", {"h":"i"}]} "
-- because Java's type, so {"a":"b", "c":[3]} is not ok
-- 2. data type in Haskell 
-- 3. find the unit, the bottom in recursion, Nothing in Maybe a
-- 4. parseT and parsers within it are calling each other, mutual-recursion

data Json = String String 
            | List [Json]
            | Map String Json deriving Show


main = print $ parse parseT "" "{\"a\":{\"b\":\"c\"},\"d\":[\"e\",\"f\",{\"h\":\"i\"}]}"
--main = print $ parse parseT "" "{\"abc\":[\"c\",\"d\"],\"b\":[\"e\"]}"
--main = print $ parse parseT "" "{\"abc\":\"c\",\"a\":\"b\"}"

parseT = parseString <|> parseList <|> parseMap <|> parseUnit <|> parseUnits
                                   
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






-- parseMap1 :: Parser Json
-- parseMap1 = try $ do
--     char '{'
--     s <- char '\"' *> (many $ noneOf "\"") <* char '\"'
--     char ':'
--     l <- char '\"' *> (many $ noneOf "\"") <* char '\"'
--     char '}'
--     return $ Map s (String l)

-- parseMap2 :: Parser Json
-- parseMap2 = try $ do
--     char '{'
--     s <- char '\"' *> (many $ noneOf "\"") <* char '\"'
--     char ':'
--     char '['
--     l <- sepBy parseT (char ',')
--     char ']'
--     char '}'
--     return $ Map s (List l)

-- parseMap3 :: Parser Json
-- parseMap3 = try $ do
--     char '{'
--     s <- char '\"' *> (many $ noneOf "\"") <* char '\"'
--     char ':'
--     l <- sepBy parseT (char ':')
--     char '}'
--     return $ Map s (Map (String (fmap head l)) (fmap last l))


-- parseT :: Parser Json
-- parseT = parseString <|> parseList <|> parseMap1 <|> parseMap2 <|> parseMap3

