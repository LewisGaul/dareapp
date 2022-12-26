module Types exposing
    ( LandingPageData
    , Model
    , Msg(..)
    , WaitingData
    )

import Browser
import Browser.Navigation as Nav
import EnTrance.Channel exposing (SendPort)
import EnTrance.Types exposing (RpcData)
import EntryPage.Types
import GameplayPage.Types
import Phases exposing (Phase)
import SharedTypes exposing (GlobalData)
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
    , phase : Phase
    }


type PhaseOld
    = CreateJoinPhase LandingPageData
    | EntryPhase EntryPage.Types.Model
    | ActivePhase GameplayPage.Types.Model2
    | WaitingPhase WaitingData


type alias LandingPageData =
    { code : String
    }


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
      --| JoinGame String
      --| GameReady (RpcData GlobalData)
    | EntryPageMsg EntryPage.Types.Msg
      --| ReceiveDares (RpcData (List String))
    | GameplayPageMsg GameplayPage.Types.Msg
