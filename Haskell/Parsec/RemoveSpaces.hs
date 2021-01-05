import Text.Parsec hiding (try)
import Text.ParserCombinators.Parsec
import Data.Char
import Data.List
import Data.Either
                                   
removeSpacesInString :: Parser [String]
removeSpacesInString = try $ do             
    p <- many $ noneOf ("\"")      
    char '\"'                      
    v <- many $ noneOf ("\"")      
    char '\"'                     
    s <- many $ noneOf ("\"")      
    return $ [(removeSpaces p),  ("\"" <> v <> "\"") , (removeSpaces s)]

-- l = "{\"a\": \"b\", \"b\":[3, 2]}"
l = "{\"a\": 3}"

result = (Right (removeEmptyString <$>))  <*>  (parse (many removeSpacesInString) ""  l)
-- Right [["{","\"a\"",":"],["\"b\"",","],["\"b\"",":[3,2]}"]]

result2 = (Right $ foldl1 (<>))  <*> result
-- Right ["{","\"a\"",":","\"b\"",",","\"b\"",":[3,2]}"]

result3 = (Right $ foldl1 (<>)) <*> result2
-- Right "{\"a\":\"b\",\"b\":[3,2]}"

main = print result3

removeSpaces :: String -> String
removeSpaces x = filter (not . isSpace) x

removeEmptyString :: [String] -> [String]
removeEmptyString x = filter ((/= 0) . length) x

