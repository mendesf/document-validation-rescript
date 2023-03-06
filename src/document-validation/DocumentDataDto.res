open Common

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

let validateResponseData = (response: FullOcr.response): result<FullOcr.analysisResult, error> => {
  switch response.data[0] {
  | Some(result) => Ok(result)
  | None => Error(EmptyResponseError)
  }
}

let validateClassificationCountry = (result: FullOcr.analysisResult): result<
  FullOcr.analysisResult,
  error,
> => {
  switch result.classification.country {
  | "BRA" => Ok(result)
  | _ => Error(InvalidDocumentCountryError)
  }
}

let getPersonName = (result: FullOcr.analysisResult): string => {
  let {enhanced: {person}, taxData} = result
  if person.name != "" {
    person.name
  } else {
    taxData.name
  }
}

let getPersonBirthdate = (result: FullOcr.analysisResult): string => {
  let {enhanced: {person}, taxData} = result
  if person.birthdate != "" {
    person.birthdate
  } else {
    taxData.birthdate
  }
}

let getPersonTaxId = (result: FullOcr.analysisResult): string => {
  let {enhanced: {person}, taxData} = result
  if person.taxId != "" {
    person.taxId
  } else {
    taxData.taxNumber
  }
}

let fromAnalysisResult = (result: FullOcr.analysisResult): result<t, error> => {
  let {classification, enhanced: {otherFields}} = result
  switch classification.\"type" {
  | "FederalID" =>
    Ok({
      doctype: #RG,
      name: getPersonName(result),
      birthdate: getPersonBirthdate(result),
      taxId: getPersonTaxId(result),
      otherFields: FederalId({
        documentId: Option.getWithDefault(otherFields.documentId, ""),
        issuedAt: Option.getWithDefault(otherFields.issuedAt, ""),
      }),
    })

  | "DriversLicense" =>
    Ok({
      doctype: #CNH,
      name: getPersonName(result),
      birthdate: getPersonBirthdate(result),
      taxId: getPersonTaxId(result),
      otherFields: DriversLicense({
        registerNumber: Option.getWithDefault(otherFields.registerNumber, ""),
        sourceDocument: Option.getWithDefault(otherFields.sourceDocument, ""),
        issuedAt: Option.getWithDefault(otherFields.issuedAt, ""),
      }),
    })

  | "Foreigners" =>
    switch classification.subtype {
    | "MigratoryRegister" =>
      Ok({
        doctype: #RNM,
        name: getPersonName(result),
        birthdate: getPersonBirthdate(result),
        taxId: getPersonTaxId(result),
        otherFields: MigratoryRegister({
          rnmId: Option.getWithDefault(otherFields.rnmId, ""),
          emission: Option.getWithDefault(otherFields.emission, ""),
        }),
      })

    | "ForeignId" =>
      Ok({
        doctype: #RNE,
        name: getPersonName(result),
        birthdate: getPersonBirthdate(result),
        taxId: getPersonTaxId(result),
        otherFields: ForeignId({
          rneId: Option.getWithDefault(otherFields.rneId, ""),
          issuedAt: Option.getWithDefault(otherFields.issuedAt, ""),
        }),
      })

    | _ =>
      Error(
        InvalidDocumentSubtypeError(
          Errors.BusinessError({
            code: "",
            details: {subtype: classification.subtype},
          }),
        ),
      )
    }

  | _ => Error(InvalidDocumentTypeError)
  }
}

let getDocumentNumber = (dto: t): string => {
  switch dto.otherFields {
  | FederalId({documentId}) => documentId
  | DriversLicense(_) => dto.taxId
  | MigratoryRegister({rnmId}) => rnmId
  | ForeignId({rneId}) => rneId
  }
}

let getDocumentIssuedAt = (dto: t): string => {
  switch dto.otherFields {
  | FederalId({issuedAt}) => issuedAt
  | DriversLicense({issuedAt}) => issuedAt
  | MigratoryRegister({emission}) => emission
  | ForeignId({issuedAt}) => issuedAt
  }
}

let toDomain = (
  ~doctype: DocumentData.Type.t,
  ~name: string,
  ~birthdate: string,
  ~number: string,
  ~issuedAt: string,
) => {
  let nameResult =
    name->DocumentData.Name.make->Errors.mapError(err => DocumentData.InvalidName(err))
  let birthdateResult =
    birthdate
    ->DocumentData.Birthdate.make
    ->Errors.mapError(err => DocumentData.InvalidBirthdate(err))
  let numberResult =
    number->DocumentData.Number.make->Errors.mapError(err => DocumentData.InvalidNumber(err))
  let issuedAtResult =
    issuedAt->DocumentData.IssuedAt.make->Errors.mapError(err => DocumentData.InvalidIssuedAt(err))

  let errors =
    []
    ->Errors.concatError(nameResult)
    ->Errors.concatError(birthdateResult)
    ->Errors.concatError(numberResult)
    ->Errors.concatError(issuedAtResult)

  switch errors {
  | [] => {
      let documentData: DocumentData.t = {
        {
          doctype,
          name: Result.getExn(nameResult),
          birthdate: Result.getExn(birthdateResult),
          number: Result.getExn(numberResult),
          issuedAt: Result.getExn(issuedAtResult),
        }
      }
      Ok(documentData)
    }

  | _ => Error(DocumentDataErrors(errors))
  }
}

let dtoToDomain = (dto: t): result<DocumentData.t, error> => {
  toDomain(
    ~doctype=dto.doctype,
    ~name=dto.name,
    ~birthdate=dto.birthdate,
    ~number=dto->getDocumentNumber,
    ~issuedAt=dto->getDocumentIssuedAt,
  )
}

let responseToDomain = (response: FullOcr.response): result<DocumentData.t, error> => {
  response
  ->validateResponseData
  ->Result.flatMap(validateClassificationCountry)
  ->Result.flatMap(fromAnalysisResult)
  ->Result.flatMap(dtoToDomain)
}

let customerToDomain = (customer: Customer.t): result<DocumentData.t, error> => {
  toDomain(
    ~doctype=customer.document.doctype,
    ~name=customer.name,
    ~birthdate=customer.birthdate->DateYMD.fromDate->DateYMD.value,
    ~number=if customer.document.doctype == #CNH {
      customer.document.taxNumber
    } else {
      customer.document.registrationNumber
    },
    ~issuedAt=customer.document.issuedAt->DateYMD.fromDate->DateYMD.value,
  )
}
