module Main exposing (main)

import Html
import Html.Attributes
import Color
import Style
import Style.Font as Font
import Style.Color as Color
import Element exposing (..)
import Element.Attributes exposing (..)


main =
    Html.beginnerProgram
        { model = model
        , update = update
        , view = view
        }
    
type alias Model =
  { navbar : String
  , leftcontent : String
  , rightcontent : { top : String, bottom : String }
  }

model : Model
model =
  { navbar = "This is the navbar"
  , leftcontent = "This is the left column content"
  , rightcontent =
    { top = "This is the right top content"
    , bottom = "This is the right bottom content"
    }
   }
 
 

update model msg = 
     model
 
type MyStyles = Navbar | Left | RightTop | RightBottom | None
 
stylesheet =
    Style.styleSheet
        [ Style.style Navbar [ Color.background Color.red ]
        , Style.style Left [ Color.background Color.blue ]
        , Style.style RightTop [Color.background Color.purple ]
        , Style.style RightBottom [Color.background Color.gray ]
        ]
 
view model =
 Element.viewport stylesheet <|
   (column None [height (percent 100) ] [
   row Navbar [height (px 30) ] [ text model.navbar ]
   , wrappedRow None [ height fill]
   [ column Left [ width (percent 50)] [ text model.leftcontent ]
   , wrappedColumn None [ width (percent 50), height fill] 
     [ el RightTop [ width fill, height fill] (text model.rightcontent.top)
     , el RightBottom [ width fill, height fill ] (text model.rightcontent.bottom)
     ]
   ]])