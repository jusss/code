import Text.Parsec hiding (try)
import Text.ParserCombinators.Parsec

main = print $ parse parseT "" "[[\"a\",\"b\"],\"c\"]"
-- Right (List [List [String "a",String "b"],String "c"])
--main = print $ parse parseString "" "\"a b\""

data T = String String | List [T] deriving Show

parseString :: Parser T
parseString = do
    char '\"'
    v <- many $ noneOf ("\"")
    char '\"'
    return $ String v


parseList :: Parser T
parseList = do
    char '['
    l <- sepBy parseT (char ',')
    char ']'
    return $ List l


parseT :: Parser T
parseT = parseString <|> parseList

-- <guest1228> koz_: I don't know how to write parseList, is it simple ?   [09:45]
-- <koz_> guest1228: Write a parser which deals with your separators (basically,
--        chucking them away), then use 'some' or 'many' (depending if zero
--        entries is valid or not) together with parseT.

-- <koz_> It's just like writing a recursive function.

-- <guest1228> koz_: but how to write a recursive parser?                  [09:47]

-- <koz_> guest1228: I literally just told you.
-- <koz_> parseT :: Parser T
-- <koz_> parseT = parseString <|> parseList
-- <koz_> Then in the definition of parseList, you use 'some parseT' or 'many
--        parseT' to get your list of entries.

-- <koz_> Depending on whether zero entries is valid or not.




    
    


    
-- data T = Int Int | List [T] deriving Show
-- --List [List [ String "a", String "b"], String "c"] :: T
-- --"[["a","b"],"c"]

-- parseInt :: Parser T
-- parseInt = do
--     l <- many digit
--     return $ Int (read l :: Int)



-- <guest122`> koz_: I tried what you said, define parseT with parseList, then
--             define parseList with parseT, and that cause definition issue,
--             parseList is not resloved in parseT because parseT is not defined
--             yet                                                         [17:29]
-- <koz_> guest122`: Show me in a pastebin?
-- <guest122`> koz_: https://paste.ubuntu.com/p/536jRCg45S/                [17:32]
-- <koz_> And the error?

-- <guest122`> koz_: https://paste.ubuntu.com/p/Jy5qQCQTHM/
-- <koz_> Are you using GHCi?
-- <guest122`> yes                                                         [17:34]
-- <koz_> That's 100% of your problem.

-- <koz_> Stop doing that.
-- <koz_> If you put that in a file and compiled it, it'd work fine.
-- <guest122`> ok, I'll try it
-- <mniip> you can use :{ multiple lines :}
-- <mniip> in ghc
-- <mniip> i
-- <guest122`> mniip: i do
-- <guest122`> koz_: you think that parseList is ok?                       [17:35]
-- <koz_> Do your lists have separators between items?
-- <koz_> Because your code doesn't deal with any as far as I can see.

-- <koz_> That's my biggest question mark.
--                                                                         [17:40]
-- <mniip> jle`, your double tape problem gave me a sequence of thoughts
-- <mniip> which led me to ponder about the homotopy theory of zippers
-- <guest122`> koz_: https://paste.ubuntu.com/p/prFCwXfwkS/

-- <koz_> guest122`: That's because line 21 is incorrect.                  [17:41]
-- <koz_> Think of the type of l.
-- <koz_> And then consider what that would imply the type of [l] to be.
-- <guest122`> use endBy?

-- <guest122`> and return List l?
-- <koz_> The second is the thing that will make that error go away.       [17:42]
-- <koz_> I don't know how endBy relates to this.

-- <guest122`> https://paste.ubuntu.com/p/MqbTRrpRpK/                      [17:44]
-- <guest122`> koz_: https://paste.ubuntu.com/p/zssvk5qxSK/                [17:45]
-- <koz_> guest122`: Look up how to parse separated lists. It's damn near 11pm
--        for me, and I'm afraid I can't instruct you in something like this.
-- <koz_> I speak as someone who is _paid money_ to debug parsers.
-- <guest122`> koz_: good night                                            [17:46]

-- <tomsmeding> guest122`: there is sepBy                                  [17:53]
-- <tomsmeding> try using that in parseList
-- <tomsmeding> at the moment, parseList just tries to read multiple things after
--              each other and knows nothing about the meaning of ',' characters

-- <guest122`> tomsmeding: but I don't know which I should use to split
--             "[[\"a\",\"b\"],\"c\"]"                                     [17:59]
-- <tomsmeding> guest122`: in parseList, between the [ ], you're trying to parse
--              multiple T's separated by ',' characters, right?           [18:00]

-- <guest122`> tomsmeding: right, but there're , inside [] and outside     [18:02]
-- <tomsmeding> sure. Does that matter?
-- <guest122`> that sepBy would not work
-- <tomsmeding> sepBy wouldn't work if it could mistake a ',' outside the list
--              for one inside your list                                   [18:03]
-- <tomsmeding> but there's a ']' in the way
-- <guest122`> so sepBy wouldn't take the outside ','?

-- <tomsmeding> saying "char ','" doesn't somehow match all commas in your
--              string, it's a parser that can consume a single comma at the
--              current cursor position

-- <tomsmeding> the parser surrounding it, for example 'sepBy' or 'many', might
--              call that parser multiple times at different positions

-- <guest122`> tomsmeding: I should change that 'many' to 'sepBy parseT (char
--             ',')'?
-- <tomsmeding> here, since parseT will not read past the ']' closing the list,
--              the "char ','" in "parseT `sepBy` char ','" will not read any
--              commas past the current list
-- <tomsmeding> yes
-- <guest122`> tomsmeding: https://paste.ubuntu.com/p/MqbTRrpRpK/
-- <tomsmeding> which is the same as parseT `sepBy` char ','

-- <tomsmeding> which I find slightly more fun to read, but it means the same :)

-- <tomsmeding> why endBy and not sepBy?                                   [18:06]

-- <tomsmeding> do you know the difference between those two?
-- <guest122`> tomsmeding: your're right https://paste.ubuntu.com/p/56Tp5Jdw4h/
--                                                                         [18:07]
-- <guest122`> tomsmeding: parse newline, should use endBy, not sepBy
-- <tomsmeding> read the documentation for endBy and for sepBy             [18:08]
-- <guest122`> sepBy would make [..., ""] to parse newline
-- <tomsmeding> then you'll understand why for trailing newlines, you usually
--              want endBy, while for separating commas, you usually want sepBy

-- <guest122`> tomsmeding: there's another question, i don't understand why
--             parseString won't work https://paste.ubuntu.com/p/Mcs6SMKDQw/
--                                                                         [18:10]

-- <tomsmeding> why do you expect the parser to match the input?
-- <tomsmeding> the input you're giving it is:  a b
-- <tomsmeding> not:  "a b"
-- <guest122`> char '\"' *> many (noneof "\"") <* char '\"'
-- <tomsmeding> lol that would be a different way to write the same thing as
--              parseString, yes                                           [18:11]
-- <tomsmeding> not necessarily more readable in my opinion
-- <guest122`> tomsmeding: you're right
-- <guest122`> tomsmeding: how I should match "a b"                        [18:13]

-- <guest122`> oh
-- <guest122`> I should use " "a b" "
