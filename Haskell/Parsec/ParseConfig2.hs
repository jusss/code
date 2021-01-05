
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

----------------------------------------------
parse (a *> b) "" input,
if a and b both are consumed on input,
return b's result, 
a is consumed, b would be consumed on the rest of input
if one of them is not consumed, then error shows up
*> is for Applicative, >> is for Monad, there's no <<
<* will return a's result

parse (many (noneOf "=") *> char '=' *> (many anyChar)) "" "ab=cd"
Right "cd"

parse (many (noneOf "=") <* (char '=')) "" "ab=cd"
Right "ab"

parse ((,) <$> (many (noneOf "=") <* (char '='))
           <*> (many anyChar)) "" "ab=cd"

Right ("ab","cd")

parse ((,) <$> (many (satisfy (== ' ')) *> (many letter) <* (many (satisfy (== ' ')))  <* (char '='))
           <*> (many (satisfy (== ' ')) *> (many (noneOf "\n ")))) "" " ab = cd "
Right ("ab","cd")

let parseString = (,) <$> (many (satisfy (== ' ')) *> (many letter) <* (many (satisfy (== ' ')))  <* (char '='))
                      <*> (many (satisfy (== ' ')) *> (many (noneOf "\n ")))
in parse (sepBy parseString newline) "" " ab = cd\nef=gh\nij = kl \n"


parseString :: Parser (String, String)
parseString = (,) <$> (many (satisfy (== ' ')) *> (many letter) <* (many (satisfy (== ' ')))  <* (char '=')) <*> (many (satisfy (== ' ')) *> (many (noneOf "\n ")))

parse (sepBy parseString newline) "" " ab = cd\nef =gh\nij= kl \n"
Right [("ab","cd"),("ef","gh"),("ij","kl")]

-----------------------------------------
<|>

parse (a <|> b) "" input,
if parser a is consumed on input, then return with a's result
b would never run, if a is failed to consume on input,
then consume b, no matter b is successful to consumed or not,
take b's result as return

--------------------------------------
<$> <*>

parse ((,) <$> a <*> b) "" input,
if parser a and b both are consumed, (,) work on a's result and b's result

parse (head <$> (many $ anyChar)) "" "a\nb" == Right 'a'
<$> make head work on the result of parser (many $ anyChar) is consumed on input "a\nb"
just like (+1) <$> (Just 2) == Just 3

------------------------------------------------------
$>

parse (a $> b) "" input, 
if a is consumed on input, then return with b as result, not a's result

<guest1218> parse (char 'a' $> 'b') "" "ac" == Right 'b', it's like if-else
<guest1218> if char 'a' consumed, then return with 'b'


-----------------------------------------------------------------


REPEAT CONSUME

I. `many parseString <* spaces <* eof` instead of `sepBy parseString newline`
if parseString consume newline then the first, otherwise the second
"server=abc.net\nport=6\n"
don't forget end of file `eof`, and end of line `endOfLine`

parseString2 :: Parser (String, String)
parseString2 = do
    spaces
    x <- many letter
    spaces
    char '='
    spaces
    y <- many (noneOf "\n ")  -- prevent \n and spaces to be consumed
    spaces -- this consume newline
    return (x,y)

--parse (many parseString2 <* spaces <* eof) "" "server = irc.freenode.net\nport = 3\nnick = john"
--Right [("server","irc.freenode.net"),("port","3"),("nick","john")]

parseString :: Parser (String, String)
parseString = do
    many (satisfy (== ' '))
    x <- many letter
    many (satisfy (== ' '))
    char '='
    many (satisfy (== ' '))
    y <- many (noneOf "\n ") -- don't consume space and newline
    return (x,y)

-- parse (sepBy parseString newline) "" "server = irc.freenode.net\nport = 3\nnick = john"
-- Right [("server","irc.freenode.net"),("port","3"),("nick","john")]

SEPBY SPLIT THEN FMAP PARSE, END WITH NEWLINE USE ENDBY
parse (sepBy parseString newline) "" "server = irc.freenode.net\nport = 3\nnick = john"
split input by newline and return a list, then parseString consume every element in that list
  -- sepBy and splitOn have the same issue, 
  -- splitOn "\n" "a\nb\n" == ["a","b",""]
  -- parse (sepBy (many (noneOf "\n")) newline) "" "server=abc\nport=6667\n"
  -- == Right ["server=abc","port=6667",""]
  -- parse (sepBy (many (noneOf "\n")) newline) "" "server=abc\nport=6667"
  -- == Right ["server=abc","port=6667"]
  -- so use endBy

USE LINES AND ENDBY TO LINE TERMINATORS, OTHERS USE SPLITON AND SEPBY

-- <glguy> guest1218, you just don't use splitOn or sepBy for line *terminators*
-- <glguy> guest1218, for parser combinators you'd use endBy instead
-- <glguy> > lines "a\nb\n" == ["a","b"]



*> CONSUME

II. *> or >> would consume matched characters, 
so parse (a *> b) "" input, if a consume matched characters in input,
then b would consume the rest of input, not entire input

SPACE CONSUME NEWLINE

III. space could consume 22 characters, not just ' ', 
space consume newline 
isSpace '\n' == True
use `satisfy (/= ' ')` to consume space, not spaces

<|> ONCE SUCCESS THEN RETRN

IIII. parse (a <|> b) "" input, if parse consume a on input successfully, 
then return with Parser action a's result, Parser action b would never work on input,
if a failed, then work b on input, no matter b success or fail, return with b's result,
a and b both work on entire input
because Parser is an Applicative and also Monad, Parser a is an action,


NONEOF IS ALREADY A PARSER

IV.
<guest1217> tomsmeding: I tried `many (satisfy (noneOf "\n "))` noneOf applied too many arguments...
<tomsmeding> many (noneOf "\n ")
<tomsmeding> noneOf is already a parser, no need to wrap it in 'satisfy'

USE FMAP FROMLIST ON RESULT

fmap fromList $ parse (sepBy parseString newline)
you can't get do Right a to fromList a, because fromList a can't turn to Left a
so Either a b -> Map a b  and   Map a b -> Either a b, 
can't do natual transform


------------------------------------------------------------------

import Text.ParserCombinators.Parsec
import Text.Parsec.Char
import Control.Applicative hiding (many)
import Data.Char

s = parse (string "server=" >> (many1 $ anyChar)) "" "server=abc"
main = print s

data Config = Config { runServer :: String,
                        runPort :: Int,
                        runNick :: String,
                        runChannel :: String,
                        runToken :: String,
                        runChatId :: Int,
                        runMode :: String }
server :: Config
server = Config "irc.freenode.net" 6667 "whatever" "#haskell" "bot9" 7 "lite"

s1 = parse (noneOf " " >> (many $ anyChar)) "" "a b"
--s2 = parse (spaces <* eof) "" "a = b"

--s3 = parse (concat <$> anyChar `sepBy` spaces) "" "a b"
s5 = parse ((many $ char ' ') *> (anyChar `sepBy` spaces)) "" " "

-- like filter, filter all the context which match those conditions
--s5 :: Parser String

s6 = parse (spaces *> many (anyChar <* spaces)) "" "  a = b   "

parseString :: Parser (String, String)
parseString = do
--    spaces
    many (satisfy (== ' '))
    x <- many letter
--    spaces
    many (satisfy (== ' '))
    char '='
--    spaces
    many (satisfy (== ' '))
--    y <- many (satisfy (/= ' '))
    y <- many (noneOf "\n ")
--    spaces
--    many (satisfy (== ' '))
    return (x,y)

--parse (sepBy parseString spaces) "" "server=irc.freenode.net port=3 nick=john"
--Right [("server","irc.freenode.net"),("port","3"),("nick","john")]

-- parse (sepBy parseString newline) "" "server = irc.freenode.net\nport = 3\nnick = john"
-- Right [("server","irc.freenode.net"),("port","3"),("nick","john")]

-- parse (endBy parseString newline) "" "server = irc.freenode.net\nport = 3\nnick = john\n"
-- Right [("server","irc.freenode.net"),("port","3"),("nick","john")]

parseString2 :: Parser (String, String)
parseString2 = do
    spaces
    x <- many letter
    spaces
    char '='
    spaces
    y <- many (noneOf "\n ")  -- prevent \n and spaces to be consumed
    spaces
    return (x,y)

--parse (many parseString2) "" "server=irc.freenode.net\nport=3\nnick=john\n"
--Right [("server","irc.freenode.net"),("port","3"),("nick","john")]    


--parse (many parseString2 <* spaces <* eof) "" "server = irc.freenode.net\nport = 3\nnick = john\n"
--Right [("server","irc.freenode.net"),("port","3"),("nick","john")]

--fmap fromList l
--Right (fromList [("nick","john"),("port","3"),("server","irc.freenode.net")])


-- *> will match the input, so `parse (newline *> anyChar) "" "\nab"` == Right 'a', if a *> b, action a and b both success, then return b and a is matched , b is the rest , b work on the rest input, not whole input
-- a <|> b   a and b both work on whole input, once success then return




<guest1217> parseString = {do; spaces; x <- many letter; spaces; char '=';
            spaces; y <- many (satisfy (/= ' ')); spaces; return (x,y)}
<guest1217> parse (sepBy parseString spaces) "" "server=irc.freenode.net
            port=3 nick=john" == Right
            [("server","irc.freenode.net"),("port","3"),("nick","john")]
<guest1217> parse (sepBy parseString newline) ""
            "server=irc.freenode.net\nport=3\nnick=john\n" == Right
            [("server","irc.freenode.net\nport=3\nnick=john\n")]  [22:28]
<guest1217> why the second is not like the first?  [22:29]
<guest1217> where it's wrong?
<tomsmeding> guest1217: perhaps parseString accepts '\n' as part of a string?
<tomsmeding> and so by the time the first parseString returns, the whole
             string has already been consumed
<guest1217> tomsmeding: parse (anyChar *> newline *> anyChar) "" "a\nc" ==
            Right 'c'  [22:30]
<guest1217> oh
<guest1217> tomsmeding: how I can change it?  [22:31]
<tomsmeding> what's the source of parseString? or does it come from a library?
<guest1217> tomsmeding: parseString = {do; spaces; x <- many letter; spaces;
            char '='; spaces; y <- many (satisfy (/= ' ')); spaces; return
            (x,y)}
<tomsmeding> that `satisfy (/= ' ')` accepts anything that's not a space,
             including, for example, newlines  [22:32]
<tomsmeding> guest1217: I suggest changing that (/= ' ') to (not . isSpace),
             where isSpace is from Data.Char
<guest1217> tomsmeding: satisfy (noneOf "\n ")?  [22:33]
<tomsmeding> guest1217: or, of course, (/= '\n') if you only want to do
             newlines
<tomsmeding> or that
<tomsmeding> depending on what you need :)
<guest1217> tomsmeding: space and newline  [22:34]
<guest1217> tomsmeding: how I can do it?
<tomsmeding> well, like you just said
<tomsmeding> also, the `spaces` at the end of `parseString` already swallows
             all spaces after the key=value pair, so the `spaces` in your
             `sepBy` will never consume anything  [22:35]
<tomsmeding> so I think you can replace `sepBy parseString spaces` and `sepBy
             parseString newline` with `many parseString`
<guest1217> tomsmeding: I tried `many (satisfy (noneOf "\n "))` noneOf applied
            too many arguments...
<tomsmeding> ah right  [22:37]
<tomsmeding> many (noneOf "\n ")
<tomsmeding> noneOf is already a parser, no need to wrap it in 'satisfy'
<guest1217> tomsmeding: parse (many parseString) ""
            "server=irc.freenode.net\nport=3\nnick=john\n" == Right
            [("server","irc.freenode.net"),("port","3"),("nick","john")]
<guest1217> tomsmeding: but why parse (sepBy parseString newline) "" "server =
            irc.freenode.net\nport = 3\nnick = john\n" == Right
            [("server","irc.freenode.net")], even I use `many (noneOf "\n ")`
                                                                        [22:42]
<tomsmeding> guest1217: I think because the `spaces` at the end of parseString
             already consumes the \n following "irc.freenode.net". By the time
             the `newline` in `sepBy parseString newline` is executed, the
             input is already at "port", meaning the `newline` doesn't match
                                                                        [22:43]
<tomsmeding> do you really need to support arbitrary newlines within your
             key=value lines? If not, perhaps it's a good idea to replace your
             uses of `spaces` within `parseString` with `many (satisfy (== '
             '))`  [22:45]
<tomsmeding> then the \n won't be consumed by parseString, and the sepBy gets
             to read it
<guest1217> tomsmeding: I remove the last spaces in parseString, then run it
            again, there's an error, it expecting white space, letter or "="
<tomsmeding> guest1217: oh right, that's the final \n at the end of your input
                                                                        [22:47]
<tomsmeding> perhaps not use `many parseString` but instead `many parseString
             <* spaces <* eof`

<guest1217> tomsmeding: if I want `sepBy parseString newline` work, how I
            should change parseString?

<tomsmeding> guest1217: read carefully what I said before :)
<tomsmeding> I suggested what I think is the right change

<guest1217> tomsmeding: final "\n" in the input?

<tomsmeding> guest1217:
             https://ircbrowse.tomsmeding.com/selection/haskell?title=Conversation&events=203120,203122,203124
<guest1217> tomsmeding: I tried to instead spaces with many (satisfy (== '
            ')), sepBy won't work  [22:56]

<guest1217> tomsmeding: you're right, I remove the last sapces and replace
            spaces with many (satisfy (== ' ')), now sepBy work
<guest1217> tomsmeding: thank you
<tomsmeding> guest1217: cool! Note that if you do that, you won't accept ' '
             characters at the end of a line  [23:00]

<dminuoso> Id love to have monthly download statistics.
<dminuoso> Bet you'd always see *parsec jumping up in december every year. :>
                                                                        [23:01]
<merijn> :p
<iqubic> Oh totally.
<tomsmeding> where * matches a non-zero length string, I guess?
<dminuoso> tomsmeding: Yes.
<dminuoso> Err. Not necessarily

<tomsmeding> because parsec itself is bundled with ghc, you're unlikely to
             download that often :p
<dminuoso> That depends on the version, though.
<iqubic> What?! Parsec is bundled with GHC? I didn't know that.  [23:02]

<iqubic> I just use Megaparsec, because 1. I love the error messages I get,
         and 2. I love that unit of measurement.

<tomsmeding> iqubic: I think this is a source of that information:
             https://gitlab.haskell.org/ghc/ghc/-/blob/master/packages
<ephemient> http://hackage.haskell.org/package/parsec old parsec, not
            megaparsec, is bundled. I prefer using the latter

<tomsmeding> iqubic: according to this wiki page (
             https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/libraries
             ), a '-' in the tag column indicates a ghc boot library  [23:04]

<tomsmeding> also before I knew what cabal even was, properly, I've been using
             parsec without problems :p
<ephemient> GHC also comes with ReadP
<dminuoso> iqubic: I find the tuple (megaparsec, attoparsec, binary) to be a
           suitable set of tools for most purposes. :)

<dminuoso> Neither is enough to cover all needs.

<guest1217> how I can turn Right [("a","b")] to fromList [("a","b")]?
            transparent transform?

<guest1217> or Right (fromList [("a","b")])?

<dminuoso> guest1217: fmap fromList
<ski> guest1217 : what should happen on `Left' ?
<guest1217> ski: I don't know...
<iqubic> ski: I assume that Right [("a","b")] is the result from calling
         parse.  [23:09]
<guest1217> iqubic: yes
<guest1217> I need to get the value by the key
<iqubic> In that case, I recommend applying fmap *before* running the parser.
<ski> if `Right (fromList [("a","b")])' is ok as result, then what dminuoso
      said (if `Left', then it'll not be changed)

<guest1217> dminuoso: yes, fmap fromList (Right ...) is ok  [23:11]

<guest1217> what about Right [...] to fromList [...]?

<guest1217> fromRight?
<iqubic> No. Just use fmap there.  [23:12]

<guest1217> iqubic: why fromRight and (~>) is not ok?
<iqubic> fromRight will give you an error if the argument is Left.  [23:13]

<merijn> s/give you an error/crash your program
<guest1217> and (~>)?  [23:15]
<iqubic> I don't know what that is.
<guest1217> natural transform?
<iqubic> Yeah, you don't want a natural transformation here.
<dminuoso> You seem to be conflating terminology here. :)
<dminuoso> A natural transformation `S ~> T` is any function `S a -> T a`,
           assuming both S and T are both functors.  [23:16]
<iqubic> I assume they are talking about this:
         https://hackage.haskell.org/package/natural-transformation-0.4/docs/Control-Natural.html#t:-126--62-

<guest1217> Right is a functor, fromList is not a functor?  [23:17]
<dminuoso> guest1217: Right is not a functor.

<merijn> Types are functors. Neither Right no "fromList" are types
<guest1217> Either a is a functor
<dminuoso> Correct.
<dminuoso> Or `Maybe`  [23:18]
<dminuoso> So a function `Either a ~> Maybe` would be a natural
           transformation.
<dminuoso> Or: Maybe ~> []
<dminuoso> That is, `Either a b -> Maybe b` or `Maybe b -> [b]`
<guest1217> what is Map?
<iqubic> Here's the main issue he's trying to solve. He has a Parser [(a, b)]
         and wants a Parser (Map a b)

<guest1217> Map a is a functor?  [23:19]
<dminuoso> No
<dminuoso> Or.. mm. `Map a` is actually I think
<dminuoso> I was thinking Set. :)
<merijn> dminuoso: Map k is a functor, yes
<merijn> dminuoso: Also Foldable and Traversable!
<dminuoso> merijn: Yeah, my head is so wired to Set at the moment
<iqubic> Map k is a functor, but that's not going to help you here.
<dminuoso> merijn: being Foldable is easy, Traversable not so much. :p
<iqubic> All he needs is a function of the type "Parser [(k,v)] -> Parse (Map
         k v)"  [23:20]
<guest1217> so Either a and Map k both are functors here, and it still can't
            turn Right a to fromList a?
<iqubic> guest1217:  ~> is not a function.
<guest1217> iqubic: ok...  [23:21]
<dminuoso> guest1217: The point here is, think of it in terms of
           functions. Let's say you have a function that can turn a `Right a`
           into `fromList a`, what would that function's type be?
<guest1217> Either a b -> Map a b?
<dminuoso> Somewhat close, but not quite. 
<merijn> eh, this seems to just be a random walk through all possible
         formulations...[  [23:23]
<dminuoso> Yeah..
<ephemient> `uncurry Map.singleton :: (a, b) -> Map a b` does exist
<guest1217> then I don't know
<ephemient> but `Either a b` and `(a, b)` are pretty different  [23:24]
<Vulfe_> they are about as different as two things can be using the same
         letters
<iqubic> guest1217: What are you trying to do?  [23:26]
<guest1217> iqubic: like you said, turn Right a to fromList a
<tomsmeding> are you sure you're not wanting to turn 'Right a' into 'Right
             (fromList a)'?
<iqubic> Why are you trying to do that? How did you get a `Right a` value?
<guest1217> get Right a by parser...  [23:28]
<ephemient> what do you expect to happen with a Left _?
<guest1217> tomsmeding: I think I should use Right (fromList a) now  [23:29]
<dminuoso> Im thinking you have piled up too many tools and bits that confuse
           you.
<guest1217> yes, there're too many things I don't understand now  [23:30]
<iqubic> Look, what he wants to do is take the result of his parser and turn
         it into a Map. I think he should use (fmap fromList) *before* parsing
         the string into a "Right a"
<dminuoso> Good. So perhaps it's helpful to backtrack to the last spot where
           you felt comfortable and understood bits.
<guest1217> ephemient: I don't know
