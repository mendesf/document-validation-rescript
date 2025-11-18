# Document Validation in ReScript

This project explores how to model a document validation domain in [ReScript](https://rescript-lang.org/), using strong typing, value objects, and functional error handling. It takes an OCR provider response, normalizes and validates the data, converts it into a rich domain model, and compares it against customer‑provided information.

## Goal

Given:
- an OCR response describing a document (name, birthdate, document number, issue date, etc.), and  
- the same data informed by the customer,

the system:

1. Validates and normalizes all input data.
2. Maps the external OCR structure into an internal domain model.
3. Compares “extracted” vs “informed” document data.
4. Returns detailed mismatch errors (e.g. name, birthdate, number).

The focus of the project is not infrastructure, but **domain modeling and validation**.

## Architecture overview

The code is organized in three main layers:

### 1. OCR / DTO / Integration layer

**Files:**  
- `src/nextcode/FullOcr.res`  
- `src/document-validation/DocumentDataDto.res`  
- `src/document-validation/DocumentDataDto.resi`

Responsibilities:

- Model the exact shape of the OCR provider response (`FullOcr.response`).
- Validate raw response data:
  - Country (`validateClassificationCountry`)
  - Document type and subtype
  - Presence and consistency of key fields
- Map the external response into an internal DTO (`DocumentDataDto.t`).
- Convert the DTO into the domain model (`DocumentData.t`), aggregating validation errors when needed.

This layer acts as an **anti‑corruption layer/DTO layer** between the external API and the core domain.

### 2. Domain layer

**Files (examples):**  
- `src/document-validation/DocumentData.res` / `.resi`  
- `src/document-validation/CompareDocumentData.res`  
- `src/common/Common.res`  
- `src/common/Errors.res`  
- `src/common/Customer.res`

#### Value Objects

The domain is modeled with several **value objects**, such as:

- `NotEmptyString`
- `NormalizedString`
- `DateYMD`
- `DocumentData.Name`
- `DocumentData.Birthdate`
- `DocumentData.Number`
- `DocumentData.IssuedAt`

Each value object:

- Has a private constructor (exposed via `.resi`) to enforce invariants.
- Exposes a `make` function that validates and normalizes input.
- Exposes a `value` function to read the primitive value when necessary.

For example, `Name` encapsulates:

- non‑empty validation,
- normalization (trim, uppercase, remove accents/symbols),
- and exposes a safe, normalized name to the rest of the system.

This follows the **Value Object pattern** from Domain‑Driven Design.

#### Domain entities

- `DocumentData.t` describes the validated document data:
  - `doctype`, `name`, `birthdate`, `number`, `issuedAt`, etc.
- `Customer.t` holds customer information, including its document.

Once a `DocumentData.t` exists, its invariants are guaranteed by the constructors of each value object.

#### Error modeling

Errors are modeled explicitly as algebraic data types:

- `common/Errors.res` defines:
  - `businessError<'a>`
  - helpers like `mapError` and `concatError` to transform and accumulate errors.
- `DocumentData.error` and `DocumentDataDto.error` define domain‑specific error cases, such as:
  - `InvalidName`
  - `InvalidBirthdate`
  - `InvalidDocumentSubtypeError`
  - `DocumentDataErrors` (list of validation errors)

Instead of throwing exceptions, functions return `result<_, error>`, which makes error handling explicit and composable.

#### Domain service: document comparison

`CompareDocumentData.res` implements a **domain service** that compares:

- `extracted: DocumentData.t` (from OCR)
- `informed: DocumentData.t` (from customer)

It provides functions like:

- `compareName`
- `compareBirthdate`
- `compareNumber`

and a higher‑level `compare` function that:

- runs all comparisons,
- accumulates any mismatches into an `array<error>`,
- returns `Ok()` when everything matches, or `Error([...])` with detailed mismatch information.

### 3. TypeScript entrypoint / adapter

**File:**  
- `src/index.ts`

This file demonstrates how to call the ReScript domain logic from TypeScript using `@genType`‑generated bindings:

- It builds a sample `FullOcr.response`.
- It builds a sample `Customer`.
- It converts both to the domain using:
  - `responseToDomain`
  - `customerToDomain`
- It calls `compare` to check if the extracted and informed data match.
- It logs the structured results as JSON.

This shows a small **hexagonal architecture** style: the core domain and validation logic live in ReScript, while TypeScript acts as an adapter at the boundary.

In a real system, this core could sit behind HTTP or messaging endpoints and use a real OCR API. Here, everything is in‑memory and synchronous on purpose, so the focus stays on the domain and the transformations.

## Patterns and techniques used

This project intentionally applies several architecture and design patterns:

- **Domain‑Driven Design (DDD) concepts**:
  - Value Objects (`Name`, `Birthdate`, `Number`, `IssuedAt`, `NotEmptyString`, `NormalizedString`, `DateYMD`)
  - Domain entities (`DocumentData`, `Customer`)
  - Domain services (`CompareDocumentData`)

- **Anti‑corruption layer / DTO mapping**:
  - `DocumentDataDto` shields the domain model from the exact shape of the OCR provider’s response.

- **Functional error handling**:
  - Extensive use of `result<'a, 'error>` instead of exceptions.
  - Typed error hierarchies (`DocumentData.error`, `DocumentDataDto.error`).
  - Helpers to map and accumulate errors (railway‑oriented style).

- **Strong encapsulation and module interfaces**:
  - `.resi` interfaces with private type constructors enforce invariants at the type level.
  - Domain modules only expose safe constructors and readers.

- **Language interop as a boundary**:
  - Domain core in ReScript, exposed to TypeScript via `@genType`, treating TypeScript as an outer adapter.

These patterns are the same ones I tend to apply when designing backend services in TypeScript/Node.js: explicit domain models, clear boundaries between external APIs and the domain, and functional-style error handling instead of exceptions.

## Running the project

Install dependencies:

```sh
npm install
```

Build:

```sh
npm run build
```

Run example:

```sh
npm start
```