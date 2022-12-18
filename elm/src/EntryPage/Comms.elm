port module EntryPage.Comms exposing (entryPageRecv, entryPageSend, notifications)

import EnTrance.Channel as Channel
import EnTrance.Feature.Gen as Gen
import EntryPage.Types exposing (Msg(..))
import Json.Decode as Decode exposing (Decoder)



-- Ports


port entryPageSend : Channel.SendPort msg


port entryPageRecv : Channel.RecvPort msg


{-| The notifications we want to decode.
-}
notifications : List (Decoder Msg)
notifications =
    [ decodeSubmitDaresResult
    ]


decodeSubmitDaresResult : Decoder Msg
decodeSubmitDaresResult =
    Gen.decodeRpc "submit_dares" (Decode.null ()) |> Decode.map SubmitDaresResult
