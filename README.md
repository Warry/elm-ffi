# Safely create JS Promise in Elm

Write JS code as String within Elm, encode arguments to JS values, then apply and get the result within a `Task`.

If your function returns a Promise, it will wait on it before completing the `Task`.

## Usage

```elm
Promise.function : List ( String, Value ) -> String -> Task Value Value
```

Takes two arguments:
- the arguments with their associated name
- the body of your function

## Example

```elm
import Promise
import Json.Encode exposing (Value)
import Task

fetchJson : String -> Task Value Value
fetchJson url =
    Promise.function
        [ ( "_url_", Json.Encode.string url )
        ]
        """
        return fetch(_url_).then((res)=> {
            if (!res.isOk) throw "oh noes :("

            return res.json()
        })
        """

```

## How safe is it?

### You can't mess with Elm generated code, you can only access function arguments and global references.

It's as safe as ports: you can't break your Elm, you can't access the runtime. It uses [Function] (rather than `eval()`) meaning that you can't import (or require) stuffs, and that it can only access global references; also meaning that there is a small performance penalty.

On the down sides syntax errors are raised when tasks are called (rather than on load), and you can't use js tooling.

Let's see how it breaks:

```elm
import Promise

windowWidth =
    Promise.function
    """
    return window.innerWidth
        //>> in a window: Ok 1440
        //>> headless: Err { "name": "ReferenceError", "message": "window is not defined" }
    """
    []

noAccessToElmFunctions =
    Promise.function
    """
    console.log(fetch)
        //>> Function
    console.log($elm$core$List$cons)
        //>> ReferenceError: $elm$core$List$cons is not defined
    console.log(__Scheduler_binding)
        //>> ReferenceError: __Scheduler_binding is not defined
    """
    []

noImports =
    Promise.function
    """
    import { val } from "my-module"
        //>> Content Security Policy
        //>> Uncaught EvalError: call to Function() blocked by CSP
    """
    []

syntaxErrorAreErrorsToo =
    Promise.function
    """
    return "forgot quote?
        //>> SyntaxError: "" string literal contains an unescaped line break
    """
    []
```

[Function]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function

