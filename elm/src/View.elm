module View exposing (view)

import Bootstrap.Grid as Grid
import Browser exposing (Document)
import EntryPage.View as EntryPage
import GameplayPage.View as GameplayPage
import Html exposing (Html)
import JoinPage.View as JoinPage
import Toasty
import Toasty.Defaults
import Types
    exposing
        ( GlobalData
        , Model
        , Msg(..)
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
        [ Grid.container []
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
            EntryPage.view p |> Html.map EntryPageMsg

        GameplayPhase p ->
            GameplayPage.view p |> Html.map GameplayPageMsg
