module JoinPage.View exposing (view)

import Bootstrap.Button exposing (button, onClick)
import Html exposing (Html, br, div, h2, text)
import JoinPage.Types exposing (Model, Msg(..), WaitingState)


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "Hello!" ]
        , viewWaitingState model.waitingState
        ]


viewWaitingState : Maybe WaitingState -> Html Msg
viewWaitingState waiting =
    case waiting of
        Nothing ->
            div [] [ button [ onClick (Join "" Nothing) ] [ text "Join" ] ]

        Just { code } ->
            div []
                [ text <| "Waiting for players to join game '" ++ code ++ "'."
                , br [] []
                , text "Share the browser link to invite another player."
                ]
