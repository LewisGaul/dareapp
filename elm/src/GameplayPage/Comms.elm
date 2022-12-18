port module GameplayPage.Comms exposing
    ( gameplayPageRecv
    , gameplayPageSend
    , notifications
    )

import EnTrance.Channel as Channel
import EnTrance.Feature.Gen as Gen
import GameplayPage.Types exposing (Msg(..))
import Json.Decode as Decode exposing (Decoder)



-- Ports


port gameplayPageSend : Channel.SendPort msg


port gameplayPageRecv : Channel.RecvPort msg


{-| The notifications we want to decode.
-}
notifications : List (Decoder Msg)
notifications =
    [ decodeOutcome
    ]


decodeOutcome : Decoder Msg
decodeOutcome =
    Gen.decodeRpc "send_outcome" Decode.string
        |> Decode.map ReceivedOutcome
