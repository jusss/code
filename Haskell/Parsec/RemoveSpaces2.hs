import Text.Parsec hiding (try)
import Text.ParserCombinators.Parsec
import Data.Char
import Data.List
import Data.Either
                                   
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


-- l = "{\"a\": \"b\", \"b\":[3, 2]}"
-- l = "{\"a\": 3}"

-- result = (Right (removeEmptyString <$>))  <*>  (parse (many removeSpacesInString) ""  l)
-- Right [["{","\"a\"",":"],["\"b\"",","],["\"b\"",":[3,2]}"]]

-- result2 = (Right $ foldl1 (<>))  <*> result
-- Right ["{","\"a\"",":","\"b\"",",","\"b\"",":[3,2]}"]

-- result3 = (Right $ foldl1 (<>)) <*> result2
-- Right "{\"a\":\"b\",\"b\":[3,2]}"

main = print $ deleteSpaces "{\"a\": \"b\", \"b\":[3, 2]}"



