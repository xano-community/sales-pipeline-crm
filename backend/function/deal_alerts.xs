// The three Salesforce Opportunity Kanban attention alerts.
// Ref: help.salesforce.com kanban_use - "three types of alerts: overdue tasks,
// no open activities, or no activity for 30 days." Closed deals never alert.
function "deal_alerts" {
  description = "Computes the three Salesforce Kanban attention flags for a deal."
  input {
    bool is_closed
    bool has_overdue_task
    bool has_open_activity
    int reference_days
  }
  stack {
    var $overdue { value = false }
    var $no_open { value = false }
    var $stale { value = false }
    conditional {
      if ($input.is_closed == false) {
        var.update $overdue { value = $input.has_overdue_task }
        var.update $no_open { value = ($input.has_open_activity == false) }
        var.update $stale { value = ($input.reference_days >= 30) }
      }
    }
    var $needs { value = ($overdue || $no_open || $stale) }
  }
  response = {
    overdue_task: $overdue,
    no_open_activities: $no_open,
    no_activity_30_days: $stale,
    needs_attention: $needs
  }

  test "closed deal never alerts" {
    input = { is_closed: true, has_overdue_task: true, has_open_activity: false, reference_days: 100 }
    expect.to_be_false ($response.needs_attention)
  }
  test "overdue task flags attention" {
    input = { is_closed: false, has_overdue_task: true, has_open_activity: true, reference_days: 2 }
    expect.to_be_true ($response.overdue_task)
    expect.to_be_true ($response.needs_attention)
  }
  test "no open activity and stale both flag" {
    input = { is_closed: false, has_overdue_task: false, has_open_activity: false, reference_days: 45 }
    expect.to_be_true ($response.no_open_activities)
    expect.to_be_true ($response.no_activity_30_days)
  }
  test "healthy open deal is calm" {
    input = { is_closed: false, has_overdue_task: false, has_open_activity: true, reference_days: 3 }
    expect.to_be_false ($response.needs_attention)
  }
  guid = "Bc41-5JxDLaRwbMCgctQN6zsXDc"
}
