module View exposing (view)

import Array
import Bootstrap.Button as Button exposing (button, onClick)
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Browser exposing (Document)
import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, maxlength, placeholder, value)
import Html.Events exposing (onInput)
import Types exposing (ActiveModel, Model, Msg(..), Options, Phase(..), SetupModel)


{-| Top-level view
-}
view : Model -> Document Msg
view model =
    { title = "Dare app"
    , body =
        [ viewErrors model.lastError
        ]
            ++ viewPhase model.phaseData model.options
    }


viewPhase : Phase -> Options -> List (Html Msg)
viewPhase phase =
    case phase of
        SetupPhase p ->
            viewSetupPhase p

        ActivePhase p ->
            viewActivePhase p

        WaitingPhase p ->
            viewWaitingPhase p


viewSetupPhase : SetupModel -> Options -> List (Html Msg)
viewSetupPhase model _ =
    let
        inputBox idx dare =
            Grid.row []
                [ Grid.col []
                    [ input
                        [ placeholder "Enter dare here"
                        , value dare
                        , onInput (DareEntry idx)
                        , maxlength 50
                        ]
                        []
                    ]
                ]
    in
    List.indexedMap inputBox (Array.toList model.inputs)
        ++ [ Grid.row []
                [ Grid.col
                    []
                    [ button
                        [ Button.primary, onClick EndSetupPhase ]
                        [ text "Done" ]
                    ]
                ]
           ]


viewActivePhase : ActiveModel -> Options -> List (Html Msg)
viewActivePhase model options =
    [ Grid.row []
        [ Grid.col []
            [ text
                ("Round "
                    ++ (options.rounds
                            - List.length model.remainingDares
                            |> String.fromInt
                       )
                    ++ "/"
                    ++ (model.remainingDares |> List.length |> String.fromInt)
                    ++ ", "
                    ++ (String.fromInt model.remainingSkips
                            ++ "/"
                            ++ String.fromInt options.skips
                            ++ " skips remaining"
                       )
                )
            ]
        ]
    , Grid.row []
        [ Grid.col []
            [ button [ Button.primary, onClick NextRound ] [ text "Next" ]
            ]
        ]
    ]


viewWaitingPhase : String -> Options -> List (Html Msg)
viewWaitingPhase model _ =
    [ text ("Waiting for other players: " ++ model) ]



-- View errors


viewErrors : Maybe String -> Html msg
viewErrors error =
    case error of
        Just e ->
            div [ class "error" ] [ text e ]

        Nothing ->
            div [] []
