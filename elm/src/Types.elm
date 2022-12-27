module Types exposing
    ( GlobalData
    , Model
    , Msg(..)
    , Options
    , Phase(..)
    , WaitingData
    )

import Browser
import Browser.Navigation as Nav
import EnTrance.Channel exposing (SendPort)
import EnTrance.Types exposing (RpcData)
import EntryPage.Types
import GameplayPage.Types
import Url



-- MODEL


type alias Model =
    { sendPort : SendPort Msg
    , lastError : Maybe String

    -- Navigation
    , basePath : String
    , navKey : Nav.Key
    , url : Url.Url

    -- Main state
    , phaseData : Phase
    }


type alias GlobalData =
    { sessionCode : String
    , options : Options
    }


type alias Options =
    { players : Int
    , rounds : Int
    , skips : Int
    }


type Phase
    = CreateJoinPhase GlobalData
    | EntryPhase (EntryPage.Types.Model GlobalData)
    | ActivePhase (GameplayPage.Types.Model GlobalData)
    | WaitingPhase WaitingData


type alias WaitingData =
    { message : String
    , globalData : GlobalData
    }



-- MESSAGES


type Msg
    = ChannelIsUp Bool
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | Error String
    | JoinGame String
    | JoinGameResult (RpcData String)
    | GameReady (RpcData GlobalData)
    | EntryPageMsg EntryPage.Types.Msg
    | ReceiveDares (RpcData (List String))
    | GameplayPageMsg GameplayPage.Types.Msg
