// Whole days between two epoch-millisecond timestamps (floored).
// Used to record days_in_previous_stage on each stage transition (Salesforce
// OpportunityHistory records a new entry on every stage change).
function "calc/days_between" {
  description = "Whole days between two epoch-millisecond timestamps, floored (never negative)."
  input {
    int from_ts
    int to_ts
  }
  stack {
    var $diff {
      description = "Elapsed milliseconds between the two timestamps"
      value = $input.to_ts - $input.from_ts
    }
    // Clamp negative spans to zero so days-in-stage is never negative
    conditional {
      if ($diff < 0) {
        var.update $diff {
          description = "Clamp a negative span to zero"
          value = 0
        }
      }
    }
    var $days {
      description = "Whole days in the span, flooring partial days"
      value = ($diff / 86400000)|floor
    }
  }
  response = $days

  test "one day" {
    input = { from_ts: 0, to_ts: 86400000 }
    expect.to_equal ($response) { value = 1 }
  }
  test "three days" {
    input = { from_ts: 0, to_ts: 259200000 }
    expect.to_equal ($response) { value = 3 }
  }
  test "negative clamps to zero" {
    input = { from_ts: 86400000, to_ts: 0 }
    expect.to_equal ($response) { value = 0 }
  }
  guid = "QKAYINFhML0h1218szeFc32DkVA"
}
