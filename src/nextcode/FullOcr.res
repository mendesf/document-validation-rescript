type otherFields = {
  documentId?: string,
  registerNumber?: string,
  sourceDocument?: string,
  rnmId?: string,
  rneId?: string,
  emission?: string,
  issuedAt?: string,
}

type person = {
  taxId: string,
  name: string,
  birthdate: string,
}

type enhanced = {
  person: person,
  otherFields: otherFields,
}

type taxData = {
  taxNumber: string,
  name: string,
  birthdate: string,
}

type matches = {
  name: bool,
  birthdate: bool,
}

type classification = {
  \"type": string,
  country: string,
  subtype: string,
}

type analysisResult = {
  enhanced: enhanced,
  taxData: taxData,
  matches: matches,
  classification: classification,
}

@genType
type response = {data: array<analysisResult>}
