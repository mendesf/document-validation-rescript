module String = Js.String2
module Array = Belt.Array
module Result = Belt.Result
module Option = Belt.Option

module NotEmptyString: {
  @genType @unboxed
  type t = private NotEmptyString(string)
  @genType
  type error = Errors.businessError<unit>
  let make: (~fieldName: string=?, string) => result<t, error>
  let isNotEmpty: (~fieldName: string=?, string) => result<string, error>
  let value: t => string
} = {
  @unboxed
  type t = NotEmptyString(string)
  type error = Errors.businessError<unit>

  let isNotEmpty = (~fieldName="", str: string): result<string, error> => {
    let trimmedStr = String.trim(str)
    if String.length(trimmedStr) == 0 {
      Errors.BusinessError({
        code: "",
        message: String.trim(`${fieldName} input must not be empty`),
      })->Error
    } else {
      Ok(trimmedStr)
    }
  }

  let make = (~fieldName="", str: string): result<t, error> => {
    isNotEmpty(~fieldName, str)->Result.map(strOk => NotEmptyString(strOk))
  }

  let value = (name: t): string => {
    let NotEmptyString(innerValue) = name
    innerValue
  }
}

module NormalizedString: {
  @genType @unboxed
  type t = private NormalizedString(string)
  type error = NotEmptyString.error
  let make: (~fieldName: string=?, string) => result<t, error>
  let normalize: string => string
  let value: t => string
} = {
  @unboxed
  type t = NormalizedString(string)
  type error = NotEmptyString.error

  let moreThanOneSpace = %re("/\s{2,}/g")
  let nonAlphanumericOrSpace = %re("/[^\w ]|_/g")

  let normalize = (str: string): string => {
    str
    ->String.normalizeByForm("NFD")
    ->String.replaceByRe(_, moreThanOneSpace, " ")
    ->String.replaceByRe(_, nonAlphanumericOrSpace, "")
    ->String.trim
    ->String.toUpperCase
  }

  let make = (~fieldName="", str: string): result<t, error> => {
    NotEmptyString.isNotEmpty(~fieldName, str)
    ->Result.map(normalize)
    ->Result.map(strOk => NormalizedString(strOk))
  }

  let value = (name: t): string => {
    let NormalizedString(innerValue) = name
    innerValue
  }
}

module DateYMD: {
  @genType @unboxed
  type t = private DateYMD(string)
  type formatErrorDetails = {input: string}
  @genType @unboxed
  type error = InvalidStringFormatError(Errors.businessError<formatErrorDetails>)
  let make: (~fieldName: string=?, string) => result<t, error>
  let fromDate: Js.Date.t => t
  let toDate: t => option<Js.Date.t>
  let value: t => string
} = {
  @unboxed
  type t = DateYMD(string)
  type formatErrorDetails = {input: string}
  @unboxed
  type error = InvalidStringFormatError(Errors.businessError<formatErrorDetails>)

  let format = %re("/^\d{4}-\d{2}-\d{2}$/")

  let make = (~fieldName="", dateStr: string): result<t, error> => {
    if Js.Re.test_(format, dateStr) {
      DateYMD(dateStr)->Ok
    } else {
      InvalidStringFormatError(
        Errors.BusinessError({
          code: "",
          message: String.trim(j`$fieldName input must respect the format: $format`),
          details: {input: dateStr},
        }),
      )->Error
    }
  }

  let value = (dateYMD: t): string => {
    let DateYMD(innerValue) = dateYMD
    innerValue
  }

  let fromDate = (date: Js.Date.t): t => {
    let yearStr = Js.Date.getFullYear(date)->Belt.Float.toString
    let monthStr = (Js.Date.getMonth(date) +. 1.0)->Belt.Float.toString
    let dateStr = Js.Date.getDate(date)->Belt.Float.toString

    let monthStr = if String.length(monthStr) == 2 {
      monthStr
    } else {
      "0" ++ monthStr
    }

    let dateStr = if String.length(dateStr) == 2 {
      dateStr
    } else {
      "0" ++ dateStr
    }

    DateYMD(`${yearStr}-${monthStr}-${dateStr}`)
  }

  let toDate = (dateYMD: t): option<Js.Date.t> => {
    let dateArr =
      dateYMD
      ->value
      ->String.split("-")
      ->Array.map(v => v->Belt.Float.fromString->Belt.Option.getWithDefault(_, 0.0))

    switch dateArr {
    | [year, month, date] => Js.Date.makeWithYMD(~year, ~month=month -. 1.0, ~date, ())->Some
    | _ => None
    }
  }
}
