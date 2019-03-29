module Main exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Html.Attributes exposing (style)

type alias Model =
    { hidden : Bool }

initialModel : Model
initialModel =
    { hidden = False }

type Msg
    = Hide
    | Show

update : Msg -> Model -> Model
update msg model =
    case msg of
        Hide ->
            { model | hidden = True }
        Show ->
            { model | hidden = False }

view : Model -> Html Msg
view model =
    let
        btn =
            if model.hidden then
                button [ onClick Show ] [ text "Show" ]
            else
                button [ onClick Hide ] [ text "Hide" ]
        displayStyle =
            if model.hidden then
                style "display" "none"
            else
                style "display" "block"
    in
    div []
        [ div [style "width" "200px", style "height" "200px", style "border" "3px green solid", displayStyle] [ text "I can be hidden" ]
        , btn
        ]

main : Program () Model Msg
main =
    Browser.sandbox
        { init = initialModel
        , view = view
        , update = update
        }

