import { compare } from "./document-validation/CompareDocumentData.gen";
import { customerToDomain } from "./document-validation/DocumentDataDto.gen";
import { responseToDomain } from "./document-validation/DocumentDataDto.gen";

const response = responseToDomain({
  data: [
    {
      classification: {
        type: "Foreigners",
        subtype: "ForeignId",
        country: "BRA",
      },
      enhanced: {
        person: {
          taxId: "",
          name: "aa  423423",
          birthdate: "",
        },
        otherFields: {
          rneId: "Q123456-0",
          issuedAt: "2017-08-04",
        },
      },
      taxData: {
        taxNumber: "",
        name: "",
        birthdate: "2015-01-09",
      },
      matches: { name: false, birthdate: false },
    },
  ],
});

const customer = customerToDomain({
  id: 1,
  name: "aa",
  birthdate: new Date(2015, 0, 9),
  document: {
    doctype: "RNE",
    registrationNumber: "Q123456-0",
    taxNumber: "",
    issuedAt: new Date(2017, 7, 4),
  },
});

console.log("response", JSON.stringify(response, undefined, 2));
console.log("customer", JSON.stringify(customer, undefined, 2));

if (response.tag == "Ok" && customer.tag == "Ok") {
  const result = compare({
    informed: customer.value,
    extracted: response.value,
  });

  console.log("result", JSON.stringify(result, undefined, 2));
}
