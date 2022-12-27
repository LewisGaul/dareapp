module Utils.ViewHelper exposing (viewError)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)


viewError : Maybe String -> Html msg
viewError error =
    case error of
        Just e ->
            div [ class "error" ] [ text e ]

        Nothing ->
            div [] []
