this is a tool for bridge IRC channels to Telegram

telegram-api for haskell https://github.com/klappvisor/haskell-telegram-api

howItWorks :: yourTelegramAccount -> TelegramBot -> IRC2Telegram -> IRC

in your telegram account conversation with your telegram bot, 

send messages to irc syntax: #channel msg

send irc commands syntax: /COMMAND PARAMETERS

usage: 

#channel message

/time      -- just other valid irc commands, start them with /

/prefix #channel

/prefix nick    -- it's equal to /msg or /query

/prefix #channel nick or /prefix #channel nick1 nick2

message  -- after you use `/prefix #channel' then you can send message directly

/set a #channel nick1 nick2  -- then 'a messgaes' replace 'a' with '#channel nick'

/unset  -- clear all the alias, 'a messages' will be send as it is


1. compile code to native code

    git clone haskell https://github.com/klappvisor/haskell-telegram-api.git 

    cd haskell-telegram-api

    cabal v2-build

    cp ~/I2T16.hs ./

    ghc I2T16.hs 

2. edit the config file

    vim I2T16.config

    -- create a bot from BotFather on telegram, then get its token and your telegram account's chatId, search and add that bot, then start it

    -- there're `normal` and `lite` modes, normal mode will show IRC channel prefix, lite mode won't

    -- edit your IRC and telegram info

    -- NOTE: DO NOT USE THE SAME TELEGRAM API TOKEN IN TWO PROGRAMS AT THE SAME TIME, IT WILL CAUSE IRC FLOOD AND GET BANNED!

3. run the script

    bash I2T16.sh
