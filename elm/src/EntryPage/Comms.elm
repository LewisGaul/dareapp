port module EntryPage.Comms exposing
    ( entryPageRecv
    , entryPageSend
    , notifications
    , subscriptions
    )

import EnTrance.Channel as Channel
import EnTrance.Feature.Gen as Gen
import EntryPage.Types exposing (Msg(..))
import Json.Decode as Decode exposing (Decoder)



-- Ports


port entryPageSend : Channel.SendPort msg


port entryPageRecv : Channel.RecvPort msg


subscriptions : Sub Msg
subscriptions =
    Channel.sub entryPageRecv Error notifications


{-| The notifications we want to decode.
-}
notifications : List (Decoder Msg)
notifications =
    [ decodeSubmitDaresResult
    ]


decodeSubmitDaresResult : Decoder Msg
decodeSubmitDaresResult =
    Gen.decodeRpc "submit_dares" (Decode.null ()) |> Decode.map SubmitDaresResult
