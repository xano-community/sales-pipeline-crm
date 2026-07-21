// Cumulative, unweighted forecast rollup by Salesforce Forecast Category.
// Ref: help.salesforce.com forecasts3_cumulative_columns_overview -
//   Open Pipeline = Pipeline + Best Case + Commit
//   Best Case Forecast = Best Case + Commit + Closed
//   Commit Forecast = Commit + Closed
//   Closed Only = Closed
// Category rollups are raw (unweighted) amounts. `weighted_expected` is the
// separate probability-weighted ExpectedRevenue sum over open deals.
function "forecast_rollup" {
  description = "Cumulative unweighted forecast rollup by Salesforce forecast category, plus a weighted expected-revenue total."
  input {
    json deals
  }
  stack {
    var $pipeline { value = 0 }
    var $best { value = 0 }
    var $commit { value = 0 }
    var $closed { value = 0 }
    var $weighted { value = 0 }
    foreach ($input.deals) {
      each as $d {
        conditional {
          if ($d.forecast_category == "Pipeline") {
            var.update $pipeline { value = $pipeline + $d.amount }
          }
        }
        conditional {
          if ($d.forecast_category == "BestCase") {
            var.update $best { value = $best + $d.amount }
          }
        }
        conditional {
          if ($d.forecast_category == "Commit") {
            var.update $commit { value = $commit + $d.amount }
          }
        }
        conditional {
          if ($d.forecast_category == "Closed") {
            var.update $closed { value = $closed + $d.amount }
          }
        }
        conditional {
          if ($d.status == "open") {
            var.update $weighted { value = $weighted + ($d.amount * $d.probability / 100) }
          }
        }
      }
    }
  }
  response = {
    pipeline: $pipeline,
    best_case: $best,
    commit: $commit,
    closed: $closed,
    open_pipeline: ($pipeline + $best + $commit),
    best_case_forecast: ($best + $commit + $closed),
    commit_forecast: ($commit + $closed),
    closed_only: $closed,
    weighted_expected: $weighted|round:2
  }

  test "cumulative rollup matches Salesforce columns" {
    input = { deals: [
      { forecast_category: "Pipeline", amount: 10000, probability: 10, status: "open" },
      { forecast_category: "BestCase", amount: 20000, probability: 70, status: "open" },
      { forecast_category: "Commit",   amount: 30000, probability: 90, status: "open" },
      { forecast_category: "Closed",   amount: 40000, probability: 100, status: "won" }
    ] }
    expect.to_equal ($response.open_pipeline) { value = 60000 }
    expect.to_equal ($response.commit_forecast) { value = 70000 }
    expect.to_equal ($response.best_case_forecast) { value = 90000 }
    expect.to_equal ($response.closed_only) { value = 40000 }
  }
  test "weighted expected counts only open deals" {
    input = { deals: [
      { forecast_category: "Commit", amount: 10000, probability: 90, status: "open" },
      { forecast_category: "Closed", amount: 50000, probability: 100, status: "won" }
    ] }
    expect.to_equal ($response.weighted_expected) { value = 9000 }
  }
  guid = "NAPwaANiiiNRk_rSx6WqxjHGpWY"
}
