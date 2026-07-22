// Per-rep forecast: closed-won this book vs quota (attainment % + Salesforce
// color band) alongside weighted open pipeline. Managers get every rep; a rep
// gets just their own line.
query "forecast" verb=GET {
  api_group = "Analytics"
  description = "Per-rep quota attainment (won vs quota, color band) and weighted open pipeline."
  auth = "user"
  input {}
  stack {
    db.get "user" {
      description = "Load the acting user to decide manager-wide vs own-book scope"
      field_name = "id"
      field_value = $auth.id
    } as $me
    var $is_mgr {
      description = "True when the acting user is a manager (sees every rep)"
      value = ($me.role == "manager")
    }
    db.query "user" {
      description = "List all reps/managers, alphabetized, to build forecast rows"
      sort = { name: "asc" }
    } as $users
    var $rows {
      description = "Accumulator for the per-rep forecast rows"
      value = []
    }
    // Managers get a row per rep; a rep only sees their own line
    foreach ($users) {
      description = "Walk each user and build their forecast row if in scope"
      each as $u {
        conditional {
          if ($is_mgr == true || $u.id == $auth.id) {
            group {
              description = "Accumulate this rep's won amount and weighted open pipeline"
              stack {
                db.query "deal" {
                  description = "Pull every deal owned by this rep"
                  where = $db.deal.owner_id == $u.id
                } as $udeals
                var $won_amount {
                  description = "Running total of this rep's closed-won amount"
                  value = 0
                }
                var $weighted_open {
                  description = "Running total of this rep's weighted open pipeline"
                  value = 0
                }
                foreach ($udeals) {
                  description = "Tally won amount and weighted open pipeline across the rep's deals"
                  each as $d {
                    conditional {
                      if ($d.status == "won") {
                        var.update $won_amount {
                          description = "Add this closed-won deal's amount to the won total"
                          value = $won_amount + $d.amount
                        }
                      }
                    }
                    conditional {
                      if ($d.status == "open") {
                        var.update $weighted_open {
                          description = "Add this open deal's ExpectedRevenue to weighted pipeline"
                          value = $weighted_open + $d.expected_revenue
                        }
                      }
                    }
                  }
                }
              }
            }
            group {
              description = "Roll up the rep's totals into a forecast row"
              stack {
                var $att {
                  description = "Quota attainment %: won amount over quota (0 when no quota set)"
                  value = (($u.quota_amount == null || $u.quota_amount == 0) ? 0 : (($won_amount * 100 / $u.quota_amount)|round:1))
                }
                function.run "attainment_band" {
                  description = "Map attainment % to its Salesforce-style color band"
                  input = { pct: $att }
                } as $band
                var.update $rows {
                  description = "Append the assembled forecast row for this rep"
                  value = $rows|push:({
                    user_id: $u.id,
                    name: $u.name,
                    role: $u.role,
                    quota: $u.quota_amount,
                    quota_period: $u.quota_period,
                    won_amount: $won_amount,
                    weighted_open: $weighted_open|round:2,
                    attainment_pct: $att,
                    band: $band.band
                  })
                }
              }
            }
          }
        }
      }
    }
  }
  response = $rows
  guid = "I2Cutiiu0v9MOEFKcwdLfTRwMg0"
}
