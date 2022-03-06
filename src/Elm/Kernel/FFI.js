/*

import Elm.Kernel.Scheduler exposing (binding, fail, succeed)

*/


/// _FFI_log : a -> a
function _FFI_log(object) {
    console.log(object);
    return object;
}


/// _FFI_function : List ( String, Value ) -> String -> Task Value Value
var _FFI_function = F2(function(functionArguments, functionBody) {
    return _Scheduler_binding(function(callback) {
        try
        {
            var constructorArguments = [], applicationArguments = [];

            for (var remainingArguments = functionArguments; remainingArguments.b; remainingArguments = remainingArguments.b) // WHILE_CONS
            {
                constructorArguments.push(remainingArguments.a.a);
                applicationArguments.push(remainingArguments.a.b.a);
            }

            constructorArguments.push(functionBody);

            var functionHolder = Function.apply(null, constructorArguments);
            var functionResult = functionHolder.apply(null, applicationArguments);

            // if result is a Promise
            if (typeof functionResult !== 'undefined' && typeof functionResult.then === 'function' && typeof functionResult.catch === 'function')
            {
                functionResult.then(function(promiseResult) {
                    callback(_Scheduler_succeed(promiseResult));
                }).catch(function(promiseError) {
                    callback(_Scheduler_fail(promiseError));
                });
            }
            else
            {
                callback(_Scheduler_succeed(functionResult));
            }
        }
        catch(functionError)
        {
            console.log(functionError)
            callback(_Scheduler_fail(functionError));
        }
    });
});

