module GameplayPage.View exposing (view)

import Array
import Bootstrap.Button as Button exposing (button, onClick)
import Bootstrap.Grid as Grid
import GameplayPage.Types exposing (Model, Msg(..), Transition(..))
import Html exposing (Html, text)
import Types exposing (GlobalData, Options)


view : Model GlobalData -> List (Html Msg)
view model =
    let
        currentDare =
            Array.fromList model.dares
                |> Array.get model.round
                |> Maybe.withDefault "<missing>"
    in
    [ Grid.row []
        [ Grid.col []
            [ text
                ("Round "
                    ++ ((model.round + 1) |> String.fromInt)
                    ++ "/"
                    ++ (model.globalData.options.rounds |> String.fromInt)
                    ++ ", "
                    ++ String.fromInt model.remainingSkips
                    ++ "/"
                    ++ String.fromInt model.globalData.options.skips
                    ++ " skips remaining"
                )
            ]
        ]
    ]
        ++ (case model.transition of
                Ready ->
                    viewStart

                Decision ->
                    viewDecision currentDare (model.remainingSkips > 0)

                Accepted ->
                    viewDare currentDare "Accepted!"

                Refused ->
                    viewDare currentDare "Refused!"

                Finished ->
                    viewFinished
           )


viewStart : List (Html Msg)
viewStart =
    [ Grid.row []
        [ Grid.col []
            [ button [ Button.primary, onClick (NextRound True) ] [ text "Start" ]
            ]
        ]
    ]


viewDecision : String -> Bool -> List (Html Msg)
viewDecision dare skipsAllowed =
    [ Grid.row []
        [ Grid.col []
            [ text dare ]
        ]
    , Grid.row []
        [ Grid.col []
            [ button [ Button.primary, onClick (NextRound True) ] [ text "Accept" ]
            , button
                [ Button.secondary
                , onClick (NextRound False)
                , Button.disabled (skipsAllowed |> not)
                ]
                [ text "Refuse" ]
            ]
        ]
    ]


viewDare : String -> String -> List (Html Msg)
viewDare dare decision =
    [ Grid.row []
        [ Grid.col []
            [ text dare ]
        ]
    , Grid.row []
        [ Grid.col []
            [ text decision ]
        ]
    ]


viewFinished : List (Html Msg)
viewFinished =
    [ Grid.row []
        [ Grid.col []
            [ text "Game finished" ]
        ]
    ]
