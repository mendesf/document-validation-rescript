open Common

type error =
  | InvalidName(NotEmptyString.error)
  | InvalidBirthdate(DateYMD.error)
  | InvalidNumber(NotEmptyString.error)
  | InvalidIssuedAt(DateYMD.error)

module Name = {
  @unboxed
  type t = Name(string)
  type error = NotEmptyString.error

  let nonLetterOrSpace = %re("/[^a-zA-Z ]/g")

  let make = (str): result<t, error> => {
    NotEmptyString.isNotEmpty(~fieldName="Name", str)
    ->Result.map(NormalizedString.normalize)
    ->Result.map(String.replaceByRe(_, nonLetterOrSpace, ""))
    ->Result.map(String.trim)
    ->Result.map(strOk => Name(strOk))
  }

  let value = (name: t): string => {
    let Name(innerValue) = name
    innerValue
  }
}

module Birthdate = {
  type t = DateYMD.t

  let make = (str): result<t, DateYMD.error> => {
    DateYMD.make(~fieldName="Birthdate", str)
  }

  let value = DateYMD.value
}

module Number = {
  @unboxed
  type t = Number(string)
  type error = NotEmptyString.error

  let nonAlphanumeric = %re("/\W|_/g")

  let make = (str): result<t, error> => {
    NotEmptyString.isNotEmpty(~fieldName="Number", str)
    ->Result.map(NormalizedString.normalize)
    ->Result.map(String.replaceByRe(_, nonAlphanumeric, ""))
    ->Result.map(strOk => Number(strOk))
  }

  let value = (name: t): string => {
    let Number(innerValue) = name
    innerValue
  }
}

module IssuedAt = {
  type t = DateYMD.t

  let make = (str): result<t, DateYMD.error> => {
    DateYMD.make(~fieldName="IssuedAt", str)
  }

  let value = DateYMD.value
}

module Type = {
  type t = [#RG | #CNH | #RNE | #RNM]
}

type t = {
  doctype: Type.t,
  name: Name.t,
  birthdate: Birthdate.t,
  number: Number.t,
  issuedAt: IssuedAt.t,
}
