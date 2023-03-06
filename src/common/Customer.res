type document = {
  doctype: DocumentData.Type.t,
  registrationNumber: string,
  taxNumber: string,
  issuedAt: Js.Date.t,
}

@genType
type t = {
  id: int,
  name: string,
  birthdate: Js.Date.t,
  document: document,
}
