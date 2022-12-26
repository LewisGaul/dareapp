module EntryPage.View exposing (view)

import Array
import Bootstrap.Button as Button exposing (button, onClick)
import Bootstrap.Grid as Grid
import EntryPage.Types exposing (Model, Msg(..))
import Html exposing (Html, input, text)
import Html.Attributes exposing (maxlength, placeholder, value)
import Html.Events exposing (onInput)
import Types exposing (GlobalData, Options)


view : Model GlobalData -> List (Html Msg)
view model =
    let
        inputBox idx dare =
            Grid.row []
                [ Grid.col []
                    [ input
                        [ placeholder "Enter dare here"
                        , value dare
                        , onInput (DareEntry idx)
                        , maxlength 200
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
