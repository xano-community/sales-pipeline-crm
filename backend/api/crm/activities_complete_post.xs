// Complete an open activity and roll its due date up to the deal's
// LastActivityDate (Salesforce derives LastActivityDate from closed activities).
query "activities/{activity_id}/complete" verb=POST {
  api_group = "Crm"
  description = "Mark an activity completed and update the deal's last_activity_at."
  auth = "user"
  input {
    int activity_id { table = "activity" }
  }
  stack {
    db.get "activity" {
      description = "Load the activity being completed"
      field_name = "id"
      field_value = $input.activity_id
    } as $activity
    // Guard against completing an activity that does not exist
    precondition ($activity != null) {
      error_type = "notfound"
      error = "Activity not found"
    }
    db.patch "activity" {
      description = "Close the activity and mark it completed"
      field_name = "id"
      field_value = $input.activity_id
      data = { status: "completed", is_closed: true }
    } as $updated
    var $due {
      description = "Due date to roll up as the deal's last activity date, defaulting to now"
      value = ($activity.due_at == null ? now : $activity.due_at)
    }
    // Only touch the deal when the activity is linked to one
    conditional {
      if ($activity.deal_id != null) {
        db.patch "deal" {
          description = "Bump the linked deal's last_activity_at to this activity's due date"
          field_name = "id"
          field_value = $activity.deal_id
          data = { last_activity_at: $due, updated_at: now }
        }
      }
    }
  }
  response = $updated
  guid = "2lYi1LNODwkZgVytfAQdpQ7qKtA"
}
