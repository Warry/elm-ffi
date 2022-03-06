module FFI exposing (function, log, run)

{-| Library for creating Javascript FFI safely.


# FFI

@docs function, log, run

-}

import Json.Decode exposing (Value)
import Task exposing (Task)


{-| Create a Promise from JS code (as `String`), then apply it with arguments (as `List ( String, Value )`), get the result into a `Task`.

If you return a JS `Promise` it will wait for the result, the task returns the value otherwise.

    fetchJson : String -> Task Value Value
    fetchJson url =
        FFI.function
            [ ( "_url_", Json.Encode.string url )
            ]
            """
            return fetch(_url_).then((res)=> {
                if (!res.isOk) throw "oh noes :("
                    //-> Err { "name": "Error", "message": "oh noes :(" }

                return res.json()
            })
            """

-}
function : List ( String, Value ) -> String -> Task Value Value
function =
    Elm.Kernel.FFI.function


{-| Logging natively
-}
log : a -> a
log =
    Elm.Kernel.FFI.log


{-| Run a task as a worker
-}
run : Task a b -> TaskProgram
run task =
    Platform.worker
        { init =
            always
                ( ()
                , Task.attempt (always (Ok ())) task
                )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = always Sub.none
        }


type alias TaskProgram =
    Program () () (Result () ())
