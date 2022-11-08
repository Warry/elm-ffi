module FFI exposing
    ( read, function, decode
    , Error, fail, errorToString
    )

{-|

> Do not forget to setup elm-ffi (README)

@docs read, function, decode


## Manage errors

@docs Error, fail, errorToString

-}

import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Process
import Task exposing (Task)


type alias JsCode = String


{-| Quickly access global values

    language : String
    language =
        FFI.read "return window.navigator.language"
        |> Decode.decodeValue Decode.string
        |> Result.withDefault "en"

-}
read : JsCode -> Value
read code =
    Encode.object [ ( "_elm_ffi_read_", Encode.string code ) ]
        |> Decode.decodeValue (Decode.field "_elm_ffi_read_" Decode.value)
        |> Result.withDefault (Encode.string haveYouSetup)


{-| Create a JS aync function from Elm, with its parameters

    fetchJson : { url: String } -> Task Error Value
    fetchJson =
        FFI.function
            [ ( "url", .url >> Json.Encode.string )
            ]
            """
            let res = await fetch(url)
            if (!res.ok) throw res.statusText
            return await res.json()
            """

-}
function : List ( String, params -> Value ) -> JsCode -> params -> Task Error Value
function args code =
    let
        holder = create (List.map Tuple.first args) code
    in
        \params ->
            apply (List.map (Tuple.second >> (|>) params) args) holder


create : List String -> JsCode -> Value
create args code =
    Encode.object
        [ ( "_elm_ffi_create_"
            , Encode.object
                [ ( "args", Encode.list Encode.string args )
                , ( "code", Encode.string code )
                ]
            )
        ]


apply : List Value -> Value -> Task Error Value
apply params holder =
    Encode.object
        [ ( "_elm_ffi_apply_"
          , Encode.object
              [ ( "holder", holder )
              , ( "params", Encode.list identity params )
              ]
          )
        ]
        |> callback


callback : Value -> Task Error Value
callback holder =
    Decode.oneOf
        [ Decode.field "OK" Decode.value |> Decode.map Task.succeed
        , Decode.field "AW" Decode.float |> Decode.andThen (Decode.succeed << callbackAwait holder)
        , Decode.field "ER" Decode.value |> Decode.map Task.fail
        ]
        |> Decode.field "_elm_ffi_apply_"
        |> (\holderDecoder -> Decode.decodeValue holderDecoder holder)
        |> Result.withDefault (fail "FFI Error" haveYouSetup)


callbackAwait : Value -> Float -> Task Error Value
callbackAwait holder =
    Process.sleep >> Task.andThen (\_ -> callback holder)


{-| Decode values within a Task Error Value

    fetchedUser : Task FFI.Error User
    fetchedUser =
        fetchUser
            |> FFI.decode decodeUser

-}
decode : Decoder result -> Task Error Value -> Task Error result
decode decoder =
    Task.andThen (\result ->
        case Decode.decodeValue decoder result of
            Ok res ->
                Task.succeed res

            Err err ->
                Decode.errorToString err
                |> fail "JSON Decode Error"
    )



-- ERRORS --


{-| Representing JS errors

usually a JS object with a `name` and a `message`
-}
type alias Error =
    Value


{-| Explain why a Task failed providing error's name and message

    error : Task FFI.Error a
    error =
        FFI.fail "Some Error" "Some cause or solution"

-}
fail : String -> String -> Task Error a
fail title message =
    Encode.object
        [ ( "name", Encode.string title )
        , ( "message", Encode.string message )
        ]
        |> Task.fail


{-| Get a readable error
-}
errorToString : Error -> String
errorToString =
    Decode.decodeValue
        (Decode.oneOf
            [ Decode.map2
                (\name message -> name ++ ": " ++ message)
                (Decode.field "name" Decode.string)
                (Decode.field "message" Decode.string)
            , Decode.field "message" Decode.string
            , Decode.string
            , Decode.value |> Decode.map (Encode.encode 4)
            ]
        )
        >> Result.withDefault "An unknown error occured"


haveYouSetup : String
haveYouSetup =
    "Have you setup elm-ffi? https://github.com/Warry/elm-ffi#readme"
