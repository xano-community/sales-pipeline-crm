// Dashboard rollups: Salesforce-style cumulative forecast columns + weighted
// ExpectedRevenue, win rate, pipeline-by-stage, a count of stale ("no activity
// for 30 days") open deals, and a quota-attainment leaderboard. Managers see the
// whole org; reps see their own book.
query "dashboard/stats" verb=GET {
  api_group = "Analytics"
  description = "Forecast rollups, win rate, pipeline-by-stage, stale-deal count, and quota leaderboard."
  auth = "user"
  input {}
  stack {
    db.get "user" {
      description = "Load the acting user to decide manager-wide vs own-book scope"
      field_name = "id"
      field_value = $auth.id
    } as $me
    var $is_mgr {
      description = "True when the acting user is a manager (sees the whole org)"
      value = ($me.role == "manager")
    }
    db.query "deal" {
      description = "Pull the deals in scope: all deals for a manager, own book for a rep"
      where = $is_mgr == true || $db.deal.owner_id == $auth.id
    } as $deals

    function.run "forecast_rollup" {
      description = "Compute cumulative forecast columns and weighted ExpectedRevenue"
      input = { deals: $deals }
    } as $forecast

    group {
      description = "Tally won/lost/stale deals and compute the win rate"
      stack {
        var $won {
          description = "Count of closed-won deals in scope"
          value = 0
        }
        var $lost {
          description = "Count of closed-lost deals in scope"
          value = 0
        }
        var $stale {
          description = "Count of open deals with no activity for 30+ days"
          value = 0
        }
        foreach ($deals) {
          description = "Tally won/lost counts and stale open deals across the book"
          each as $d {
            conditional {
              if ($d.status == "won") {
                var.update $won {
                  description = "Increment the closed-won count"
                  value = $won + 1
                }
              }
            }
            conditional {
              if ($d.status == "lost") {
                var.update $lost {
                  description = "Increment the closed-lost count"
                  value = $lost + 1
                }
              }
            }
            conditional {
              if ($d.is_closed == false) {
                var $ref {
                  description = "Reference timestamp for staleness: last activity, else created date"
                  value = ($d.last_activity_at == null ? $d.created_at : $d.last_activity_at)
                }
                function.run "days_between" {
                  description = "Days elapsed since the deal's last activity"
                  input = { from_ts: $ref, to_ts: now }
                } as $rd
                conditional {
                  if ($rd >= 30) {
                    var.update $stale {
                      description = "Flag this open deal as stale (30+ days idle)"
                      value = $stale + 1
                    }
                  }
                }
              }
            }
          }
        }
        var $decided {
          description = "Total decided deals (won + lost) used as the win-rate denominator"
          value = $won + $lost
        }
        var $win_rate {
          description = "Win rate %: won over decided deals, guarded against divide-by-zero"
          value = ($decided == 0 ? 0 : (($won * 100 / $decided)|round:1))
        }
      }
    }

    group {
      description = "Build the pipeline-by-stage summary rows"
      stack {
        db.query "pipeline_stage" {
          description = "Load pipeline stages in board order to bucket deals by stage"
          sort = { sort_order: "asc" }
        } as $stages
        var $by_stage {
          description = "Accumulator for the pipeline-by-stage summary rows"
          value = []
        }
        foreach ($stages) {
          description = "Build a count/amount/weighted summary row for each pipeline stage"
          each as $s {
            db.query "deal" {
              description = "Fetch in-scope deals sitting in this stage"
              where = ($is_mgr == true || $db.deal.owner_id == $auth.id) && $db.deal.stage_id == $s.id
            } as $sd
            var $cnt {
              description = "Deal count in this stage"
              value = 0
            }
            var $sum {
              description = "Total deal amount in this stage"
              value = 0
            }
            var $wsum {
              description = "Total weighted ExpectedRevenue in this stage"
              value = 0
            }
            foreach ($sd) {
              description = "Sum count, amount, and weighted revenue for this stage's deals"
              each as $d2 {
                var.update $cnt {
                  description = "Increment the stage's deal count"
                  value = $cnt + 1
                }
                var.update $sum {
                  description = "Add this deal's amount to the stage total"
                  value = $sum + $d2.amount
                }
                var.update $wsum {
                  description = "Add this deal's weighted ExpectedRevenue to the stage total"
                  value = $wsum + $d2.expected_revenue
                }
              }
            }
            var.update $by_stage {
              description = "Append the assembled summary row for this stage"
              value = $by_stage|push:({ stage_id: $s.id, stage_name: $s.name, count: $cnt, amount: $sum, weighted: $wsum|round:2 })
            }
          }
        }
      }
    }

    group {
      description = "Build the quota-attainment leaderboard"
      stack {
        db.query "user" {
          description = "List users alphabetically to build the quota-attainment leaderboard"
          sort = { name: "asc" }
        } as $users
        var $leaderboard {
          description = "Accumulator for the quota-attainment leaderboard rows"
          value = []
        }
        // Managers see every rep on the leaderboard; a rep only sees their own line
        foreach ($users) {
          description = "Build a leaderboard row per in-scope rep from their closed-won total"
          each as $u {
            conditional {
              if ($is_mgr == true || $u.id == $auth.id) {
                db.query "deal" {
                  description = "Fetch this rep's closed-won deals"
                  where = $db.deal.owner_id == $u.id && $db.deal.status == "won"
                } as $uw
                var $usum {
                  description = "Running total of this rep's closed-won amount"
                  value = 0
                }
                foreach ($uw) {
                  description = "Sum the rep's closed-won amounts"
                  each as $d3 {
                    var.update $usum {
                      description = "Add this won deal's amount to the rep's total"
                      value = $usum + $d3.amount
                    }
                  }
                }
                var $att {
                  description = "Quota attainment %: won amount over quota (0 when no quota set)"
                  value = (($u.quota_amount == null || $u.quota_amount == 0) ? 0 : (($usum * 100 / $u.quota_amount)|round:1))
                }
                function.run "attainment_band" {
                  description = "Map attainment % to its Salesforce-style color band"
                  input = { pct: $att }
                } as $band
                var.update $leaderboard {
                  description = "Append the assembled leaderboard row for this rep"
                  value = $leaderboard|push:({ user_id: $u.id, name: $u.name, won_amount: $usum, quota: $u.quota_amount, attainment_pct: $att, band: $band.band })
                }
              }
            }
          }
        }
      }
    }
  }
  response = {
    forecast: $forecast,
    win_rate: $win_rate,
    won_count: $won,
    lost_count: $lost,
    stale_deals: $stale,
    pipeline_by_stage: $by_stage,
    leaderboard: $leaderboard
  }
  guid = "DH8Zd3qfWRNgUswbiFmRdv3leiU"
}
