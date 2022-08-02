it supposed to be a bug, but it accomplished a feature, 
in normal mode, the replayMsg is like "#channel nick :msg"
and reply would be like "#channel nick " <> ", msg"
and "#channel " would reply on that channel, no matter which prefix channel is.
so it's a replay feature, not a bug
and on lite mode, the replayMsg is like "nick :msg", 
and reply would be like "nick , msg", it needs a prefix channel

getResult :: [Update] -> [Maybe Text]
getResult  x = fmap (g . message) x
g :: Maybe Message -> Maybe Text
g (Just x) = case reply_to_message x of
    Nothing -> text x
    Just replyMsg -> (T.filter (/= '\128994') <$> L.head <$> (T.splitOn ":") <$> (text replyMsg)) <> (Just ", ") <> (text x)
g Nothing = Just ""


------------------------------
telegram-api depends on cabal v3,so if it's cabal v2, then update cabal

cabal install cabal-install
it will be installed in ~/.cabal/bin/cabal

mv /usr/bin/cabal /usr/bin/_cabal
ln -s ~/.cabal/bin/cabal /usr/bin/cabal

mkdir -p I2T/i2c

vim I2T/cabal.project
packages: */*.cabal

cd I2T
git clone https://github.com/klappvisor/haskell-telegram-api.git
cd I2T/i2c
cabal init # choose executable, not library 

vim I2T/haskell-telegram-api/telegram-api.cabal
build-depends:       base >= 4.7 && < 5
                      , aeson
                      , containers
                      , http-api-data
                      , http-client
                      , http-client-tls
                      , servant >= 0.16 && < 0.17
                      , servant-client >= 0.16 && < 0.17
                      , servant-client-core >= 0.16 && < 0.17
                      , mtl
                      , text
                      , transformers
                      , http-media
                      , http-types
                      , mime-types
                      , bytestring
                      , string-conversions
                      , binary
                      , network 
                      , irc 
                      , ircbot


vim I2T/i2c/i2c.cabal
main-is:             I2T20.hs
build-depends:       base >=4.13 && <4.14, telegram-api,http-client-tls, network, async, text, parsec, containers, http-client, bytestring, utf8-string

cabal v2-run i2c I2T20.config

there're `my-code arg1 arg2` and `my-code --arg1 value1 --arg2
value2` two ways to pass parameter to code, cabal can do the second way with --?
you may need to watch out for parameters with leading dashes,
which will be eaten by cabal. cabal v2-run -- my-project --whatever
it tells cabal (or stack) to stop reading parameters starting with - for itself, so they go to your program
without the `--` cabal will consume all options of the form `--*` itself, you need the bare `--` to tell it to stop


