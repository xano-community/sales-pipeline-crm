table "activity" {
  description = "Logged sales activities — tasks and events (calls, emails, meetings) tied to a deal or contact (Salesforce Task/Event)."
  auth = false
  schema {
    int id
    int deal_id? {
      description = "Deal this activity relates to, if any"
      table = "deal"
    }
    int contact_id? {
      description = "Contact this activity relates to, if any"
      table = "contact"
    }
    int owner_id {
      description = "Sales rep responsible for this activity"
      table = "user"
    }
    enum kind?="task" {
      description = "Whether this is a to-do task or a scheduled calendar event"
      values = ["task", "event"]
    }
    enum subtype?="task" {
      description = "Specific activity type: call, email, meeting, or generic task"
      values = ["call", "email", "meeting", "task"]
    }
    text subject filters=trim { description = "Short summary line for the activity" }
    text description? { description = "Detailed notes about the activity" }
    timestamp due_at? { description = "When the task is due or the event is scheduled" }
    enum status?="not_started" {
      description = "Progress state of the activity"
      values = ["not_started", "in_progress", "completed", "waiting", "deferred"]
    }
    bool is_closed?=false { description = "Whether the activity is finished and no longer actionable" }
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "deal_id"}]}
    {type: "btree", field: [{name: "contact_id"}]}
    {type: "btree", field: [{name: "owner_id"}]}
  ]
  guid = "uYgq8an0oFZiYAR_tgEzLJUXxVk"
}
