module View exposing (view)

import Bootstrap.Button exposing (button, onClick)
import Bootstrap.Grid as Grid
import Browser exposing (Document)
import EntryPage.View
import GameplayPage.View
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Types
    exposing
        ( GlobalData
        , LandingPageData
        , Model
        , Msg(..)
        , Options
        , Phase(..)
        , WaitingData
        )
import Utils exposing (viewError)


{-| Top-level view
-}
view : Model -> Document Msg
view model =
    { title = "Dare app"
    , body =
        [ viewError model.lastError
        ]
            ++ viewPhase model.phaseData
    }


viewPhase : Phase -> List (Html Msg)
viewPhase phase =
    case phase of
        CreateJoinPhase data ->
            viewLandingPage data

        EntryPhase p ->
            EntryPage.View.view p |> List.map (Html.map EntryPageMsg)

        ActivePhase p ->
            GameplayPage.View.view p |> List.map (Html.map GameplayPageMsg)

        WaitingPhase p ->
            viewWaitingPhase p


viewLandingPage : LandingPageData -> List (Html Msg)
viewLandingPage data =
    [ Grid.row []
        [ Grid.col []
            [ button [ onClick (JoinGame data.code) ] [ text "Join" ]
            ]
        ]
    ]


viewWaitingPhase : WaitingData -> List (Html Msg)
viewWaitingPhase model =
    [ text ("Waiting for other players: " ++ model.message) ]
