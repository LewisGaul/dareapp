port module EntryPage.Comms exposing
    ( entryPageRecv
    , entryPageSend
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
    Sub.batch
        [ Channel.sub entryPageRecv Error decoders
        ]


{-| Decoders for all the notifications we can receive
-}
decoders : List (Decoder Msg)
decoders =
    []
