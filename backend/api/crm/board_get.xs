// The Kanban board: stages in order, each with its deals, and per-deal the three
// Salesforce Kanban attention alerts (overdue task, no open activities, no
// activity for 30 days). Managers see all deals; reps see their own.
query "board" verb=GET {
  api_group = "Crm"
  description = "Kanban board: stages with their deals and Salesforce-style attention alerts."
  auth = "user"
  input {}
  stack {
    db.get "user" {
      field_name = "id"
      field_value = $auth.id
    } as $me
    var $is_mgr { value = ($me.role == "manager") }
    db.query "pipeline_stage" {
      sort = { sort_order: "asc" }
    } as $stages
    var $board { value = [] }
    foreach ($stages) {
      each as $s {
        db.query "deal" {
          where = ($is_mgr == true || $db.deal.owner_id == $auth.id) && $db.deal.stage_id == $s.id
          sort = { amount: "desc" }
        } as $sdeals
        var $cards { value = [] }
        foreach ($sdeals) {
          each as $d {
            db.query "activity" {
              where = $db.activity.deal_id == $d.id && $db.activity.is_closed == false
              return = { type: "count" }
            } as $open_cnt
            db.query "activity" {
              where = $db.activity.deal_id == $d.id && $db.activity.is_closed == false && $db.activity.due_at < now
              return = { type: "count" }
            } as $overdue_cnt
            var $ref_ts { value = ($d.last_activity_at == null ? $d.created_at : $d.last_activity_at) }
            function.run "days_between" {
              input = { from_ts: $ref_ts, to_ts: now }
            } as $ref_days
            function.run "deal_alerts" {
              input = {
                is_closed: $d.is_closed,
                has_overdue_task: ($overdue_cnt > 0),
                has_open_activity: ($open_cnt > 0),
                reference_days: $ref_days
              }
            } as $alerts
            var.update $cards { value = $cards|push:($d|set:"alerts":$alerts) }
          }
        }
        var.update $board { value = $board|push:({ stage: $s, deals: $cards }) }
      }
    }
  }
  response = $board
  guid = "A2OHTmKz_ii_ynRXvVwY1iuBY88"
}
