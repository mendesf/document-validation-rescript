type subtypeErrorDetails = {subtype: string}

type error =
  | EmptyResponseError
  | InvalidDocumentCountryError
  | InvalidDocumentTypeError
  | InvalidDocumentSubtypeError(Errors.businessError<subtypeErrorDetails>)
  | DocumentDataErrors(array<DocumentData.error>)
type otherFields =
  | FederalId({documentId: string, issuedAt: string})
  | DriversLicense({registerNumber: string, sourceDocument: string, issuedAt: string})
  | MigratoryRegister({rnmId: string, emission: string})
  | ForeignId({rneId: string, issuedAt: string})

type t = {
  doctype: DocumentData.Type.t,
  name: string,
  birthdate: string,
  taxId: string,
  otherFields: otherFields,
}

let fromAnalysisResult: FullOcr.analysisResult => result<t, error>
let dtoToDomain: t => result<DocumentData.t, error>
@genType
let responseToDomain: FullOcr.response => result<DocumentData.t, error>
@genType
let customerToDomain: Customer.t => result<DocumentData.t, error>
