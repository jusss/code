module Counter exposing (..)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Browser exposing (sandbox)
type alias Model = Int

type Msg
  = Inc
  | Dec

model : Model
model = 0

update : Msg -> Model -> Model
update msg model2 =
  case msg of
    Inc ->
      model2 + 1
    Dec ->
      model2 - 1


view : Model -> Html Msg
view model1 =
  div []
    [ button [ onClick Inc] [ text "Inc" ]
    , text (String.fromInt model1)
    , button [ onClick Dec ] [ text "Dec" ]
    ]

main : Program () Model Msg
main =  Browser.sandbox
       { init = model
       , view = view
        , update = update}

