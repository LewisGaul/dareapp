module GameplayPage.View exposing (view)

import Bootstrap.Button as Button exposing (button, onClick)
import Bootstrap.Grid as Grid
import GameplayPage.Types exposing (Model, Msg(..), Transition(..))
import Html exposing (Html, div, text)


view : Model -> Html Msg
view model =
    div [] []



--viewXXX : Model -> List (Html Msg)
--viewXXX model =
--    let
--        currentDare =
--            Array.fromList model.dares
--                |> Array.get model.round
--                |> Maybe.withDefault "<missing>"
--    in
--    [ Grid.row []
--        [ Grid.col []
--            [ text
--                ("Round "
--                    ++ ((model.round + 1) |> String.fromInt)
--                    ++ "/"
--                    ++ (model.globalData.options.rounds |> String.fromInt)
--                    ++ ", "
--                    ++ String.fromInt model.remainingSkips
--                    ++ "/"
--                    ++ String.fromInt model.globalData.options.skips
--                    ++ " skips remaining"
--                )
--            ]
--        ]
--    ]
--        ++ (case model.transition of
--                Ready ->
--                    viewStart
--
--                Decision ->
--                    viewDecision currentDare (model.remainingSkips > 0)
--
--                Waiting ->
--                    viewDare currentDare "Waiting for other players..."
--
--                Outcome message ->
--                    viewOutcome currentDare message
--
--                Finished ->
--                    viewFinished
--           )


viewStart : List (Html Msg)
viewStart =
    [ Grid.row []
        [ Grid.col []
            [ button [ Button.primary, onClick NextRound ] [ text "Start" ]
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
            [ button [ Button.primary, onClick (MakeDecision True) ] [ text "Accept" ]
            , button
                [ Button.secondary, onClick (MakeDecision False), Button.disabled (skipsAllowed |> not) ]
                [ text "Refuse" ]
            ]
        ]
    ]


viewDare : String -> String -> List (Html Msg)
viewDare dare message =
    [ Grid.row []
        [ Grid.col []
            [ text dare ]
        ]
    , Grid.row []
        [ Grid.col []
            [ text message ]
        ]
    ]


viewOutcome : String -> String -> List (Html Msg)
viewOutcome dare message =
    viewDare dare message
        ++ [ Grid.row []
                [ Grid.col []
                    [ button [ Button.primary, onClick NextRound ] [ text "Next round" ] ]
                ]
           ]


viewFinished : List (Html Msg)
viewFinished =
    [ Grid.row []
        [ Grid.col []
            [ text "Game finished" ]
        ]
    ]
