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
    var $is_mgr { value = ($auth.role == "manager") }
    db.query "deal" {
      where = $is_mgr == true || $db.deal.owner_id == $auth.id
    } as $deals

    function.run "forecast_rollup" {
      input = { deals: $deals }
    } as $forecast

    var $won { value = 0 }
    var $lost { value = 0 }
    var $stale { value = 0 }
    foreach ($deals) {
      each as $d {
        conditional {
          if ($d.status == "won") {
            var.update $won { value = $won + 1 }
          }
        }
        conditional {
          if ($d.status == "lost") {
            var.update $lost { value = $lost + 1 }
          }
        }
        conditional {
          if ($d.is_closed == false) {
            var $ref { value = ($d.last_activity_at == null ? $d.created_at : $d.last_activity_at) }
            function.run "days_between" {
              input = { from_ts: $ref, to_ts: now }
            } as $rd
            conditional {
              if ($rd >= 30) {
                var.update $stale { value = $stale + 1 }
              }
            }
          }
        }
      }
    }
    var $decided { value = $won + $lost }
    var $win_rate { value = ($decided == 0 ? 0 : (($won * 100 / $decided)|round:1)) }

    db.query "pipeline_stage" {
      sort = { sort_order: "asc" }
    } as $stages
    var $by_stage { value = [] }
    foreach ($stages) {
      each as $s {
        db.query "deal" {
          where = ($is_mgr == true || $db.deal.owner_id == $auth.id) && $db.deal.stage_id == $s.id
        } as $sd
        var $cnt { value = 0 }
        var $sum { value = 0 }
        var $wsum { value = 0 }
        foreach ($sd) {
          each as $d2 {
            var.update $cnt { value = $cnt + 1 }
            var.update $sum { value = $sum + $d2.amount }
            var.update $wsum { value = $wsum + $d2.expected_revenue }
          }
        }
        var.update $by_stage {
          value = $by_stage|push:({ stage_id: $s.id, stage_name: $s.name, count: $cnt, amount: $sum, weighted: $wsum|round:2 })
        }
      }
    }

    db.query "user" {
      sort = { name: "asc" }
    } as $users
    var $leaderboard { value = [] }
    foreach ($users) {
      each as $u {
        conditional {
          if ($is_mgr == true || $u.id == $auth.id) {
            db.query "deal" {
              where = $db.deal.owner_id == $u.id && $db.deal.status == "won"
            } as $uw
            var $usum { value = 0 }
            foreach ($uw) {
              each as $d3 {
                var.update $usum { value = $usum + $d3.amount }
              }
            }
            var $att { value = (($u.quota_amount == null || $u.quota_amount == 0) ? 0 : (($usum * 100 / $u.quota_amount)|round:1)) }
            function.run "attainment_band" {
              input = { pct: $att }
            } as $band
            var.update $leaderboard {
              value = $leaderboard|push:({ user_id: $u.id, name: $u.name, won_amount: $usum, quota: $u.quota_amount, attainment_pct: $att, band: $band.band })
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
