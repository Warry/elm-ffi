module FFI exposing (function)

{-| Library for creating Javascript FFI safely.

@docs function

-}

import Json.Decode exposing (Value)
import Task exposing (Task)


{-| Create a Task with JS code from Elm

If you return a JS `Promise` it will wait for the result,
otherwise the task result is the return value.

    fetchJson : String -> Task Value Value
    fetchJson url =
        FFI.function
            [ ( "_url_", Json.Encode.string url )
            ]
            """
            return fetch(_url_).then((res)=> {
                if (!res.ok) throw res.statusText
                return res.json()
            })
            """

-}
function : List ( String, Value ) -> String -> Task Value Value
function =
    Elm.Kernel.FFI.function
