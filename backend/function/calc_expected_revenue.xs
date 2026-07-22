// Salesforce Opportunity.ExpectedRevenue = Amount * Probability.
// Ref: developer.salesforce.com Object Reference - Opportunity ("Read-only field
// that is equal to the product of the opportunity Amount field and the Probability").
function "calc_expected_revenue" {
  description = "Weighted expected revenue for a deal: amount * probability / 100 (Salesforce ExpectedRevenue)."
  input {
    decimal amount
    int probability
  }
  stack {
    var $expected {
      description = "Weighted expected revenue: amount * probability / 100, rounded to cents"
      value = ($input.amount * $input.probability / 100)|round:2
    }
  }
  response = $expected

  test "90% of 10000 is 9000" {
    input = { amount: 10000, probability: 90 }
    expect.to_equal ($response) { value = 9000 }
  }
  test "0% probability yields 0" {
    input = { amount: 50000, probability: 0 }
    expect.to_equal ($response) { value = 0 }
  }
  test "50% of 24000 is 12000" {
    input = { amount: 24000, probability: 50 }
    expect.to_equal ($response) { value = 12000 }
  }
  guid = "sF4_hwmYv_-f50ku5n3gV8XcfxY"
}
