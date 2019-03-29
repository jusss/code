module Hide exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Browser

type Msg = Hide | Show
type alias Model = String

--model : Model
--model = "block"
initModel:Model
initModel="block"
    
view : Model -> Html Msg
view model = div [ ]
             [ button [ onClick Hide] [ text "Hide" ]
              , h1 [ style "display" model ] [ text "hi" ]
              , button [ onClick Show ] [ text "Show"]
              ]

update : Msg -> Model -> Model
update msg model =
     case msg of
         Hide -> "none"
         Show -> "block"

main = Browser.sandbox {
          init = initModel
         ,update = update
         ,view = view
          }
