port module Comms exposing (appSend, subscriptions)

import EnTrance.Channel as Channel
import EnTrance.Feature.Gen as Gen
import EntryPage.Comms
import GameplayPage.Comms
import Json.Decode as Decode exposing (Decoder)
import Types exposing (GlobalData, Msg(..))



{- PORTS

   - `appSend` - send message to the server
   - `appRecv` - receive a notification from the server
   - `appIsUp` - get notifications of up/down status
   - `errorRecv` - get any global errors
-}


port appSend : Channel.SendPort msg


port appRecv : Channel.RecvPort msg


port appIsUp : Channel.IsUpPort msg


port errorRecv : Channel.ErrorRecvPort msg


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ errorRecv Error
        , appIsUp ChannelIsUp
        , Channel.sub appRecv Error notifications
        , Sub.map EntryPageMsg EntryPage.Comms.subscriptions
        ]


{-| The notifications we want to decode.
-}
notifications : List (Decoder Msg)
notifications =
    [ decodeReceivedDares
    , decodeGameReady
    , decodeJoinGameResult
    ]
        ++ List.map (Decode.map EntryPageMsg) EntryPage.Comms.notifications
        ++ List.map (Decode.map GameplayPageMsg) GameplayPage.Comms.notifications


decodeReceivedDares : Decoder Msg
decodeReceivedDares =
    Gen.decodeRpc "send_dares" (Decode.list Decode.string)
        |> Decode.map ReceiveDares


decodeGlobalData : Decoder GlobalData
decodeGlobalData =
    Decode.map2 GlobalData
        (Decode.field "session_code" Decode.string)
        (Decode.map3 Types.Options
            (Decode.field "players" Decode.int)
            (Decode.field "rounds" Decode.int)
            (Decode.field "skips" Decode.int)
        )


decodeGameReady : Decoder Msg
decodeGameReady =
    Gen.decodeRpc "game_ready" decodeGlobalData
        |> Decode.map GameReady


decodeJoinGameResult : Decoder Msg
decodeJoinGameResult =
    Gen.decodeRpc "join_game" Decode.string
        |> Decode.map JoinGameResult
