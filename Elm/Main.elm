port module Main exposing (..)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Browser exposing (sandbox)
type alias Model = Int

type Msg
  = Inc
  | Dec
  | GetHello Int                               --Three, Msg is a type constructor, Inc or Dec or GetHello all are value constructor, Inc and Dec don't have a parameter, GetHello has one parameter Int, GetHello 3's type is Msg, but GetHello "what" type is not Msg

model : Model
model = 0

port sayHello : String -> Cmd msg             -- 1, send function's signature
port jsHello : (Int -> msg)  -> Sub msg        --One, receive function jsHello's signature, value constructor can be used as function, and it can do match pattern

init : flags -> ( Model, Cmd Msg )
init dataFromJSwhenInit = (model, Cmd.none)

update : Msg -> Model  -> (Model, Cmd msg)
update msg x =
  case msg of
    Inc ->
      (x + 1, sayHello "i")
    Dec ->
      (x - 1, sayHello "d")
    GetHello y ->                             --Four, value constructor is used for match pattern, msg's type is Msg
     (x + y, sayHello "from JS")


view : Model -> Html Msg
view x =
  div []
    [ button [ onClick Inc] [ text "Inc" ]
    , text (String.fromInt x)
    , button [ onClick Dec ] [ text "Dec" ]
    ]

subscriptions : Model -> Sub Msg
subscriptions x = jsHello GetHello     --Two, specify the value constructor, when jsHello get message from outside JS


main : Program () Model Msg
main =  Browser.element
       { init = init
       , view = view
        , update = update , subscriptions = subscriptions}
