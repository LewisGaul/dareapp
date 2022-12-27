module Utils.Misc exposing (decodeOptions, decodeRequest, toAlphaNum)

import EnTrance.Feature.Gen as Gen
import EnTrance.Types exposing (RpcData)
import Json.Decode as Decode exposing (Decoder)
import Utils.Types exposing (Options)


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


decodeRequest : String -> Decoder a -> (RpcData a -> msg) -> Decoder msg
decodeRequest req decoder makeMsg =
    Gen.decodeRpc req decoder
        |> Decode.map makeMsg


decodeOptions : Decoder Options
decodeOptions =
    Decode.map3 Options
        (Decode.field "players" Decode.int)
        (Decode.field "rounds" Decode.int)
        (Decode.field "skips" Decode.int)
