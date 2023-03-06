open Common

module Name: {
  @unboxed
  type t = private Name(string)
  type error = NotEmptyString.error
  let make: string => result<t, error>
  let value: t => string
}

module Birthdate: {
  type t = DateYMD.t
  let make: string => result<t, DateYMD.error>
  let value: t => string
}

module Number: {
  @unboxed
  type t = private Number(string)
  type error = NotEmptyString.error
  let make: string => result<t, error>
  let value: t => string
}

module IssuedAt: {
  type t = DateYMD.t
  let make: string => result<t, DateYMD.error>
  let value: t => string
}

module Type: {
  type t = [#RG | #CNH | #RNE | #RNM]
}

@genType
type t = {
  doctype: Type.t,
  name: Name.t,
  birthdate: Birthdate.t,
  number: Number.t,
  issuedAt: IssuedAt.t,
}

@genType
type error =
  | InvalidName(Name.error)
  | InvalidBirthdate(DateYMD.error)
  | InvalidNumber(NotEmptyString.error)
  | InvalidIssuedAt(DateYMD.error)
