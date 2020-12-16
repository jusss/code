import Control.Applicative
main :: IO ()
main = (getLine >>= print) <|> (print "interrupt")

-- if you input "ok" it will show ok
-- press C-c, it will show interrupt
-- <|> can handle IO exception, 
-- run and return the first successful computation, failed then next

<|> can handle IO exception, but <|> is not required by any Applicative or Monad, it's required by Alternative


<|> will run the first action and return, if it's failed, then next
"pick the first one. if it fails, pick the second one"

Nothing <|> Just 1 == Just 1
Just 1 <|> Just 2 == Just 1
<iqubic> <|> requires an Alternative instance. Those are Monads that can fail,
         for some definition of fail. If the first action succeeds, then that
         action will be returned and the second action will never be run. If
         the first action fails, then the second action's result will be
         returned, regardless of if the second action succeeded or faild.


<iqubic> Alternative is the type class that provides the (<|>) operator.
<iqubic> <|> will handle any IO exception.                              [15:50]
<guest1216> what about main = (getLine >>= print) <|> (print "failed")
<guest1216> iqubic: I input ok, and it print ok, I use C-c in terminal, it print "failed"
<idnar> many Applicatives are Alternative, but not all                  [15:53]
<guest1216> what about other Exception like read/write file?
<iqubic> <|> will handle any IO exception.                              [15:50]
<guest1216> Exception in other language like python and kotlin, they use
            try/except to handle
<guest1216> but all runtime exceptions are IO exception?
<iqubic> There are functions that work like try/except in Haskell too.
<iqubic> guest1216: Yes. All runtime exceptions are IO exceptions.      [15:51]
<guest1216> iqubic: wait a sec, must <|> be implement for every application or
            monad?
<iqubic> No. That's not true.                                           [15:52]


<iqubic> If you look at the list of instances you'll see "Applicative (ParsecT
         s u m)" This shows that a parser is an applicative.            [15:37]
<guest1216> IO action getLine failed by C-c
<iqubic> Yes. That's correct.
<iqubic> If you use C-c, then the getLine will fail, causing the other effect
         to be used.
<guest1216> but I don't see some functions defined in Application are
            implemented in Parsec, like many, I saw there's many1       [15:39]
<iqubic> many is defined in Control.Applicative, and will work for all
         Alternatives. Since a Parsec Parser is an Alternative, it can just
         use the definition of many as given in Control.Applicative.    [15:41]
<iqubic> :t (<|>)
<lambdabot> Alternative f => f a -> f a -> f a
<iqubic> Note the Alternative constraint.                               [15:55]
