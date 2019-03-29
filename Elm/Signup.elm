module Signup exposing (..)
import Html exposing (Html, div, h1, form, text, input, button)
import Html.Attributes exposing (..)
import Browser

type alias User =
    { name : String
    , email : String
    , password : String
    , loggedIn : Bool
    }

type alias Model
    = User

initialModel : User
initialModel =
    { name = ""
    , email = ""
    , password = ""
    , loggedIn = False
    }

headerStyle : Html.Attribute msg
headerStyle =
    style "padding-left" "15cm"


view : User -> Html msg
view user =
    div []
        
    [ h1 [style "padding-left" "15cm"
    , style "color" "green"
    ] [ text "Sign up" ]
        , Html.form []
            [ div []
                [ text "Name"
                , input
                    [ id "name"
                    , type_ "text"
                    ]
                    []
                ]
            , div []
                [ text "Email"
                , input
                    [ id "email"
                    , type_ "email"
                    ]
                    []
                ]
            , div []
                [ text "Password"
                , input
                    [ id "password"
                    , type_ "password"
                    ]
                    []
                ]
            , div []
                [ button
                    [ type_ "submit" ]
                    [ text "Create my account" ]
                ]
            ]
        ]

update : msg -> User -> User
update msg model =
    initialModel


main =
    Browser.sandbox
        { init = initialModel
        , view = view
        , update = update
        }