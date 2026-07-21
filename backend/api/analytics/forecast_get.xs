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
      field_name = "id"
      field_value = $auth.id
    } as $me
    var $is_mgr { value = ($me.role == "manager") }
    db.query "user" {
      sort = { name: "asc" }
    } as $users
    var $rows { value = [] }
    foreach ($users) {
      each as $u {
        conditional {
          if ($is_mgr == true || $u.id == $auth.id) {
            db.query "deal" {
              where = $db.deal.owner_id == $u.id
            } as $udeals
            var $won_amount { value = 0 }
            var $weighted_open { value = 0 }
            foreach ($udeals) {
              each as $d {
                conditional {
                  if ($d.status == "won") {
                    var.update $won_amount { value = $won_amount + $d.amount }
                  }
                }
                conditional {
                  if ($d.status == "open") {
                    var.update $weighted_open { value = $weighted_open + $d.expected_revenue }
                  }
                }
              }
            }
            var $att { value = (($u.quota_amount == null || $u.quota_amount == 0) ? 0 : (($won_amount * 100 / $u.quota_amount)|round:1)) }
            function.run "attainment_band" {
              input = { pct: $att }
            } as $band
            var.update $rows {
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
  response = $rows
  guid = "I2Cutiiu0v9MOEFKcwdLfTRwMg0"
}
