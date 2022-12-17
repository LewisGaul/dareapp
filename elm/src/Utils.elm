module Utils exposing (Key(..), keyDecode, toAlphaNum)

import Json.Decode as Decode exposing (Decoder)



-- Key presses


type Key
    = Escape
    | Enter
    | Other


keyDecoder : Decoder Key
keyDecoder =
    Decode.map toKey (Decode.field "key" Decode.string)


keyDecode : Key -> a -> Decoder a
keyDecode key a =
    let
        decodeResult k =
            if keysMatch key k then
                Decode.succeed a

            else
                Decode.fail "Not the escape key"
    in
    keyDecoder |> Decode.andThen decodeResult


{-| Convert a KeyboardEvent.Key value to an Elm Key.

See <https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key/Key_Values>

-}
toKey : String -> Key
toKey string =
    case string of
        "Escape" ->
            Escape

        -- Old IE/Firefox
        "Esc" ->
            Escape

        "Enter" ->
            Enter

        _ ->
            Other


keysMatch : Key -> Key -> Bool
keysMatch k1 k2 =
    -- This is ridiculous, is this really the best way to do this?
    case k1 of
        Escape ->
            case k2 of
                Escape ->
                    True

                _ ->
                    False

        Enter ->
            case k2 of
                Enter ->
                    True

                _ ->
                    False

        Other ->
            False



-- Misc


toAlphaNum : String -> String
toAlphaNum string =
    let
        convChar char =
            if Char.isAlphaNum char then
                char

            else
                '-'
    in
    List.map convChar (String.toList string) |> String.fromList
