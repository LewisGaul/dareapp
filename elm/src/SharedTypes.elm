module SharedTypes exposing (GlobalData, Options, dummyGlobalData)


type alias GlobalData =
    { sessionCode : String
    , options : Options
    }


type alias Options =
    { players : Int
    , rounds : Int
    , skips : Int
    }


dummyGlobalData : GlobalData
dummyGlobalData =
    { sessionCode = "foo"
    , options =
        { players = 2
        , rounds = 10
        , skips = 5
        }
    }
