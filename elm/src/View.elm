module View exposing (view)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Bootstrap.Grid.Col as Col
import Browser exposing (Document)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Types exposing (Model, Msg(..))


{-| Top-level view
-}
view : Model -> Document Msg
view model =
    { title = "Dare app"
    , body =
        [ div [] [ text "hello" ]
        , viewErrors model.lastError
        , exampleBootstrap
        ]
    }


exampleBootstrap : Html Msg
exampleBootstrap =
    Grid.row
    [ Row.centerXs ]
    [ Grid.col
        [ Col.xs12
        , Col.attrs [ class "custom-class" ]
        ]
        [ text "Some full width column."]
    ]


-- View errors


viewErrors : Maybe String -> Html msg
viewErrors error =
    case error of
        Just e ->
            div [ class "error" ] [ text e ]

        Nothing ->
            div [] []
