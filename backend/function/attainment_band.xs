// Quota-attainment color band, mirroring Salesforce Collaborative Forecasts.
// Ref: help.salesforce.com forecasts3_quotas_intro - attainment is shown with
// color-coded progress (grey 0%, red 1-33%, orange 34-66%, green 67%+).
function "attainment_band" {
  description = "Maps a quota-attainment percentage to Salesforce's color band (grey/red/orange/green)."
  input {
    decimal pct
  }
  stack {
    var $band { value = "grey" }
    conditional {
      if ($input.pct >= 1 && $input.pct < 34) {
        var.update $band { value = "red" }
      }
    }
    conditional {
      if ($input.pct >= 34 && $input.pct < 67) {
        var.update $band { value = "orange" }
      }
    }
    conditional {
      if ($input.pct >= 67) {
        var.update $band { value = "green" }
      }
    }
  }
  response = { band: $band, pct: $input.pct }

  test "zero is grey" {
    input = { pct: 0 }
    expect.to_equal ($response.band) { value = "grey" }
  }
  test "twenty is red" {
    input = { pct: 20 }
    expect.to_equal ($response.band) { value = "red" }
  }
  test "fifty is orange" {
    input = { pct: 50 }
    expect.to_equal ($response.band) { value = "orange" }
  }
  test "eighty is green" {
    input = { pct: 80 }
    expect.to_equal ($response.band) { value = "green" }
  }
  guid = "tnYgfLgqpEIi3MLlcKgcFUzrgGk"
}
