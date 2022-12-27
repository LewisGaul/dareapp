module View exposing (view)

import Bootstrap.Grid as Grid
import Browser exposing (Document)
import EntryPage.View as EntryPage
import GameplayPage.View as GameplayPage
import Html exposing (Html, div, h2, text)
import JoinPage.View as JoinPage
import Toasty
import Toasty.Defaults
import Types
    exposing
        ( GlobalData
        , Model
        , Msg(..)
        , Options
        , Phase(..)
        )
import Utils.Toast as Toast
import Utils.ViewHelper exposing (viewError)


{-| Top-level view
-}
view : Model -> Document Msg
view model =
    { title = "Dare app"
    , body =
        [ h2 [] [ text "Hello!" ]
        , Grid.container []
            [ viewError model.lastError
            , viewPhase model.phaseData
            , Toasty.view Toasty.Defaults.config Toast.view ToastyMsg model.toasties
            ]
        ]
    }


viewPhase : Phase -> Html Msg
viewPhase phase =
    case phase of
        JoinPhase p ->
            JoinPage.view p |> Html.map JoinPageMsg

        EntryPhase p ->
            EntryPage.view p |> List.map (Html.map EntryPageMsg) |> div []

        GameplayPhase p ->
            GameplayPage.view p |> Html.map GameplayPageMsg
