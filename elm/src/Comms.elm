port module Comms exposing (appSend, subscriptions)

import EnTrance.Channel as Channel
import EntryPage.Comms as EntryPage
import GameplayPage.Comms as GameplayPage
import JoinPage.Comms as JoinPage
import Json.Decode as Decode exposing (Decoder)
import Types exposing (GlobalData, Msg(..))
import Utils.Inject as Inject
import Utils.Misc exposing (decodeOptions, decodeRequest)
import Utils.Types exposing (Options)



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
        [ appIsUp ChannelIsUp
        , errorRecv Error
        , Inject.sub Injected
        , Sub.map JoinPageMsg JoinPage.subscriptions
        , Sub.map EntryPageMsg EntryPage.subscriptions
        , Sub.map GameplayPageMsg GameplayPage.subscriptions
        , Channel.sub appRecv Error decoders
        ]


decoders : List (Decoder Msg)
decoders =
    [ decodeRequest "start_entry_phase" decodeCodePlayerAndOptions StartEntryPhaseNotification
    , decodeRequest "start_game_phase" decodeOptions StartGameplayPhaseNotification
    , decodeRequest "reconnect" GameplayPage.decodeModel ReconnectionResult
    ]


decodeCodePlayerAndOptions : Decoder ( String, Int, Options )
decodeCodePlayerAndOptions =
    Decode.map3 (\x y z -> ( x, y, z ))
        (Decode.field "code" Decode.string)
        (Decode.field "player_id" Decode.int)
        decodeOptions
