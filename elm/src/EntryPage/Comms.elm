port module EntryPage.Comms exposing
    ( entryPageRecv
    , entryPageSend
    , subscriptions
    )

import EnTrance.Channel as Channel
import EntryPage.Types exposing (Msg(..))
import Json.Decode as Decode exposing (Decoder)
import Utils.Misc exposing (decodeRequest)


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
    [ decodeRequest "submit_dares" (Decode.map (\_ -> ()) Decode.string) SubmitDaresResult
    ]
