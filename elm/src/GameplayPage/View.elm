module GameplayPage.View exposing (view)

import Bootstrap.Button as Button exposing (button, onClick)
import Bootstrap.Grid as Grid
import GameplayPage.Types exposing (Model, Msg(..), Transition(..), roundFromTransition)
import Html exposing (Html, br, div, h2, text)


view : Model -> Html Msg
view model =
    div [] <|
        [ h2 [] [ text "Game time!" ]
        , viewHeader model (roundFromTransition model.transition model.options.rounds)
        , br [] []
        , case model.transition of
            Ready ->
                viewStart

            LoadingRound _ ->
                viewLoading

            Decision dareState ->
                viewDecision dareState.dare (model.remainingSkips > 0)

            Waiting dareState message ->
                viewDare dareState.dare (message ++ ", waiting for other players to decide...")

            Outcome dareState message ->
                viewOutcome dareState.dare message

            Finished ->
                viewFinished
        ]


viewHeader : Model -> Int -> Html Msg
viewHeader model round =
    text <|
        "Round "
            ++ String.fromInt round
            ++ "/"
            ++ String.fromInt model.options.rounds
            ++ ", "
            ++ String.fromInt model.remainingSkips
            ++ "/"
            ++ String.fromInt model.options.skips
            ++ " skips remaining"


viewStart : Html Msg
viewStart =
    button [ Button.primary, onClick NextRound ] [ text "Start" ]


viewLoading : Html Msg
viewLoading =
    text "Loading..."


viewDecision : String -> Bool -> Html Msg
viewDecision dare skipsAllowed =
    div []
        [ text dare
        , Grid.row []
            [ Grid.col []
                [ button [ Button.primary, onClick (MakeDecision True) ] [ text "Accept" ]
                , button
                    [ Button.secondary, onClick (MakeDecision False), Button.disabled (skipsAllowed |> not) ]
                    [ text "Refuse" ]
                ]
            ]
        ]


viewDare : String -> String -> Html Msg
viewDare dare message =
    div []
        [ text dare
        , br [] []
        , text message
        ]


viewOutcome : String -> String -> Html Msg
viewOutcome dare message =
    div []
        [ viewDare dare message
        , br [] []
        , button [ Button.primary, onClick NextRound ] [ text "Next round" ]
        ]


viewFinished : Html Msg
viewFinished =
    text "Game finished"
