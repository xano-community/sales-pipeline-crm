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
      description = "Load the acting user to check whether they are a manager"
      field_name = "id"
      field_value = $auth.id
    } as $me
    var $is_mgr {
      description = "True when the acting user has the manager role"
      value = ($me.role == "manager")
    }
    db.query "pipeline_stage" {
      description = "Fetch all pipeline stages in board order"
      sort = { sort_order: "asc" }
    } as $stages
    var $board {
      description = "Accumulator for the ordered stage columns and their deal cards"
      value = []
    }
    foreach ($stages) {
      description = "Build one board column per pipeline stage"
      each as $s {
        db.query "deal" {
          description = "Deals in this stage the user may see (managers: all; reps: their own), highest value first"
          where = ($is_mgr == true || $db.deal.owner_id == $auth.id) && $db.deal.stage_id == $s.id
          sort = { amount: "desc" }
        } as $sdeals
        var $cards {
          description = "Accumulator for this stage's deal cards with attention alerts"
          value = []
        }
        foreach ($sdeals) {
          description = "Compute Salesforce-style attention alerts for each deal card"
          each as $d {
            db.query "activity" {
              description = "Count open (not closed) activities on the deal"
              where = $db.activity.deal_id == $d.id && $db.activity.is_closed == false
              return = { type: "count" }
            } as $open_cnt
            db.query "activity" {
              description = "Count open activities on the deal whose due date has passed"
              where = $db.activity.deal_id == $d.id && $db.activity.is_closed == false && $db.activity.due_at < now
              return = { type: "count" }
            } as $overdue_cnt
            var $ref_ts {
              description = "Reference timestamp for staleness: last activity date, or created date if none"
              value = ($d.last_activity_at == null ? $d.created_at : $d.last_activity_at)
            }
            function.run "days_between" {
              description = "Days since the deal's last activity"
              input = { from_ts: $ref_ts, to_ts: now }
            } as $ref_days
            function.run "deal_alerts" {
              description = "Derive the overdue-task, no-open-activity, and stale alert flags"
              input = {
                is_closed: $d.is_closed,
                has_overdue_task: ($overdue_cnt > 0),
                has_open_activity: ($open_cnt > 0),
                reference_days: $ref_days
              }
            } as $alerts
            var.update $cards {
              description = "Append the deal card with its alerts to this stage"
              value = $cards|push:($d|set:"alerts":$alerts)
            }
          }
        }
        var.update $board {
          description = "Append the stage column with its deal cards to the board"
          value = $board|push:({ stage: $s, deals: $cards })
        }
      }
    }
  }
  response = $board
  guid = "A2OHTmKz_ii_ynRXvVwY1iuBY88"
}
