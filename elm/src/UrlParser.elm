module UrlParser exposing (urlParser)

import Types exposing (GlobalData)
import Url.Parser as Parser exposing ((<?>))
import Url.Parser.Query as Query


urlParser : Parser.Parser (GlobalData -> a) a
urlParser =
    Parser.map constructGlobalData <|
        Parser.string
            <?> Query.int "rounds"
            <?> Query.int "skips"


constructGlobalData : String -> Maybe Int -> Maybe Int -> GlobalData
constructGlobalData code rounds skips =
    let
        options =
            case ( rounds, skips ) of
                ( Just r, Just s ) ->
                    { rounds = r, skips = s, players = 2 }

                ( Just r, Nothing ) ->
                    { rounds = r, skips = r // 2, players = 2 }

                ( Nothing, Just s ) ->
                    { rounds = 10, skips = s, players = 2 }

                ( Nothing, Nothing ) ->
                    { rounds = 10, skips = 5, players = 2 }
    in
    { sessionCode = code, options = options }
