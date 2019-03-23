port module Main exposing (..)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Browser exposing (sandbox)
type alias Model = Int

type Msg
  = Inc
  | Dec
  | GetHello Int                               --Three, parameter function's signature

model : Model
model = 0

port sayHello : String -> Cmd msg             -- 1, send function's signature
port jsHello : (Int -> msg)  -> Sub msg        --One, receive function jsHello's signature

init : flags -> ( Model, Cmd Msg )
init dataFromJSwhenInit = (model, Cmd.none)

update : Msg -> Model  -> (Model, Cmd msg)
update msg x =
  case msg of
    Inc ->
      (x + 1, sayHello "i")
    Dec ->
      (x - 1, sayHello "d")
    GetHello y ->                             --Four, parameter function's definition
     (x + y, sayHello "from JS")


view : Model -> Html Msg
view x =
  div []
    [ button [ onClick Inc] [ text "Inc" ]
    , text (String.fromInt x)
    , button [ onClick Dec ] [ text "Dec" ]
    ]

subscriptions : Model -> Sub Msg
subscriptions x = jsHello GetHello     --Two, specify the receive function's name


main : Program () Model Msg
main =  Browser.element
       { init = init
       , view = view
        , update = update , subscriptions = subscriptions}
