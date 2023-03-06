module Array = Belt.Array

type baseError<'a> = BusinessError({code: string, message?: string, details?: 'a})

@genType
type businessError<'a> = baseError<'a>

type systemError<'a> = baseError<'a>

type mapError<'a, 'b, 'c> = (result<'a, 'b>, 'b => 'c) => result<'a, 'c>

let mapError: mapError<'a, 'b, 'c> = (result, make) => {
  switch result {
  | Ok(success) => Ok(success)
  | Error(failure) => Error(make(failure))
  }
}

type concatError<'a, 'b> = (array<'b>, result<'a, 'b>) => array<'b>

let concatError: concatError<'a, 'b> = (arr, result) => {
  switch result {
  | Ok(_) => []
  | Error(err) => [err]
  }->Array.concat(arr)
}
