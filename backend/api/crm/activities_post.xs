// Log an activity (call/email/meeting/task) against a deal. A meeting is stored
// as an Event; everything else as a Task. Completing the activity updates the
// deal's LastActivityDate (Salesforce: most recent closed task/event due date).
query "deals/{deal_id}/activities" verb=POST {
  api_group = "Crm"
  description = "Log an activity on a deal; a completed activity updates last_activity_at."
  auth = "user"
  input {
    int deal_id { table = "deal" }
    text subject filters=trim
    text subtype? filters=trim|lower
    int contact_id?
    text description?
    timestamp due_at?
    bool completed?
  }
  stack {
    var $subtype { value = ($input.subtype == null ? "task" : $input.subtype) }
    var $kind { value = ($subtype == "meeting" ? "event" : "task") }
    var $completed { value = ($input.completed == null ? false : $input.completed) }
    var $status { value = ($completed == true ? "completed" : "not_started") }
    var $due { value = ($input.due_at == null ? now : $input.due_at) }
    db.add "activity" {
      data = {
        deal_id: $input.deal_id,
        contact_id: $input.contact_id,
        owner_id: $auth.id,
        kind: $kind,
        subtype: $subtype,
        subject: $input.subject,
        description: $input.description,
        due_at: $due,
        status: $status,
        is_closed: $completed
      }
    } as $activity
    conditional {
      if ($completed == true) {
        db.patch "deal" {
          field_name = "id"
          field_value = $input.deal_id
          data = { last_activity_at: $due, updated_at: now }
        }
      }
    }
  }
  response = $activity
  guid = "VL3-E3HnFv11ytW3-ccgkO5qpxk"
}
