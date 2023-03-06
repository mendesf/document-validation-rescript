module String = Js.String2
module Array = Belt.Array

type error = NotMatchError({message: string, field: string, extracted: string, informed: string})

type documentDataPair = {
  extracted: DocumentData.t,
  informed: DocumentData.t,
}

let compareName = (pair: documentDataPair): result<documentDataPair, error> => {
  let {extracted, informed} = pair

  if extracted.name == informed.name {
    Ok(pair)
  } else {
    NotMatchError({
      message: "Name does not match",
      field: "name",
      extracted: extracted.name->DocumentData.Name.value,
      informed: informed.name->DocumentData.Name.value,
    })->Error
  }
}

let compareBirthdate = (pair: documentDataPair): result<documentDataPair, error> => {
  let {extracted, informed} = pair
  if extracted.birthdate == informed.birthdate {
    Ok(pair)
  } else {
    NotMatchError({
      message: "Birthdate does not match",
      field: "birthdate",
      extracted: extracted.birthdate->DocumentData.Birthdate.value,
      informed: informed.birthdate->DocumentData.Birthdate.value,
    })->Error
  }
}

let compareNumber = (pair: documentDataPair): result<documentDataPair, error> => {
  let {extracted, informed} = pair
  if extracted.number == informed.number {
    Ok(pair)
  } else {
    NotMatchError({
      message: "Number does not match",
      field: "number",
      extracted: extracted.number->DocumentData.Number.value,
      informed: informed.number->DocumentData.Number.value,
    })->Error
  }
}

@genType
let compare = (pair: documentDataPair): result<unit, array<error>> => {
  let errors =
    [compareName, compareBirthdate, compareNumber]->Array.flatMap(fn =>
      fn(pair)->Errors.concatError([], _)
    )

  switch errors {
  | [] => Ok()
  | _ => Error(errors)
  }
}
