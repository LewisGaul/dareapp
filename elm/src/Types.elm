module Types exposing (ActiveModel, Model, Msg(..), Options, Phase(..), SetupModel, SharedData)

import Array exposing (Array)
import Browser
import Browser.Navigation as Nav
import EnTrance.Channel exposing (SendPort)
import EnTrance.Types exposing (RpcData)
import Url



-- MODEL


type alias Model =
    { sendPort : SendPort Msg
    , lastError : Maybe String

    -- Navigation
    , basePath : String
    , navKey : Nav.Key
    , url : Url.Url

    -- Data
    , code : String
    , options : Options
    , phaseData : Phase
    , sharedData : SharedData
    }


type alias Options =
    { players : Int
    , rounds : Int
    , skips : Int
    }


type Phase
    = SetupPhase SetupModel
    | ActivePhase ActiveModel
    | WaitingPhase String


type alias SetupModel =
    { inputs : Array String
    }


type alias ActiveModel =
    { remainingDares : List String
    , remainingSkips : Int
    , currentDare : Maybe String
    }


type alias SharedData =
    { allDares : List String
    }



-- MESSAGES


type Msg
    = ChannelIsUp Bool
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | DareEntry Int String
    | EndSetupPhase
    | SubmitDaresResult (RpcData ())
    | CollectDares (RpcData (List String))
    | NextRound
    | Error String
