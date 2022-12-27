module EntryPage.View exposing (view)

import Array
import Bootstrap.Button as Button exposing (button, onClick)
import Bootstrap.Grid as Grid
import EntryPage.Types exposing (Model, Msg(..))
import Html exposing (Html, div, h2, input, text)
import Html.Attributes exposing (maxlength, placeholder, style, value)
import Html.Events exposing (onInput)


view : Model -> Html Msg
view model =
    let
        inputBox idx dare =
            Grid.row []
                [ Grid.col []
                    [ input
                        [ placeholder "Enter dare here"
                        , value dare
                        , onInput (DareEntry idx)
                        , maxlength 250
                        , style "width" "100%"
                        ]
                        []
                    ]
                ]
    in
    div []
        ([ h2 [] [ text "Enter dares" ] ]
            ++ List.indexedMap inputBox (Array.toList model.inputs)
            ++ [ button
                    [ Button.primary, onClick SubmitDares ]
                    [ text "Done" ]
               ]
            ++ [ viewWaitingState model.waitingState ]
        )


viewWaitingState : Bool -> Html Msg
viewWaitingState waiting =
    if waiting then
        div [] [ text "Waiting for remaining players to enter their dares..." ]

    else
        div [] []
