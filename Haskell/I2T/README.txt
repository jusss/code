###########       What is this?              ######################

this is a tool for bridging IRC channels to Telegram Bots

based on telegram-api for haskell https://github.com/klappvisor/haskell-telegram-api

howItWorks :: yourTelegramAccount -> TelegramBot -> I2T -> IRC


############      What's the syntax?       ###################

usage in Telegram: 

#channel message -- send messages to IRC

/command parameters  -- send IRC commands

/time      -- just another valid irc commands, start them with /

/prefix #channel

/prefix nick    -- it's equal to /msg or /query, `/prefix nickserv` `help identify` are same to "/msg nickserv help identify"
                -- "/msg nickserv identify nick password" is same to `/prefix nickserv` `identify nick password`

/prefix #channel nick or /prefix #channel nick1 nick2

message  -- after you use `/prefix #channel` then you can send messages directly

/set a #channel nick1 nick2  -- then 'a messgaes' replace 'a' with '#channel nick'

/unset  -- clear all the alias, 'a messages' will be send as it is

swipe from right to left on message to reply others from IRC, it will quote the original message from IRC

############    How to use it?     ######################

# Download the binary release file I2T.tar.xz from above, it's for linux on amd64 only

1. tar -xvJf I2T.tar.xz

2. cd I2T; vim I2T20.config  # change your info

3. bash I2T20.sh



###########   Wanna build from source?    #########################

1. compile code to native code

    git clone haskell https://github.com/klappvisor/haskell-telegram-api.git 

    cd haskell-telegram-api

    cabal v2-build

    cp ~/I2T20.hs ./

    ghc I2T20.hs 

2. edit the config file

    vim I2T20.config

    -- create a bot from BotFather on telegram, then get its token and your telegram account's chatId, search and add that bot, then start it

    -- there're `normal` and `lite` modes, normal mode will show IRC channel prefix, lite mode won't

    -- edit your IRC and telegram info

    -- NOTE: DO NOT USE THE SAME TELEGRAM API TOKEN IN TWO PROGRAMS AT THE SAME TIME, IT WILL CAUSE IRC FLOOD AND GET BANNED!

    -- mode = lite or normal
    mode = lite
    server = irc.libera.chat
    port = 6665
    nick = x
    password = x
    channel = #x
    token = bot9
    chatId = 7

3. run the script

    bash I2T20.sh
