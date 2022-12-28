module Utils.Types exposing (Options, PlayerID, SessionCode)


type alias SessionCode =
    String


type alias PlayerID =
    Int


type alias Options =
    { players : Int
    , rounds : Int
    , skips : Int
    }
