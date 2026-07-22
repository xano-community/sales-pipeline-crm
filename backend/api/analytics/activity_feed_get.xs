// Recent pipeline activity for the dashboard's History rail: the latest stage
// transitions across deals, joined to the deal, the user who made the change, and
// the destination stage. Newest first.
query "activity-feed" verb=GET {
  api_group = "Analytics"
  description = "Recent stage-change history across deals (for the dashboard activity feed)."
  auth = "user"
  input {}
  stack {
    db.query "deal_stage_history" {
      description = "Fetch the latest stage transitions joined to deal, actor, and destination stage"
      join = {
        deal: { table: "deal", where: $db.deal_stage_history.deal_id == $db.deal.id }
        user: { table: "user", where: $db.deal_stage_history.changed_by == $db.user.id }
        pipeline_stage: { table: "pipeline_stage", where: $db.deal_stage_history.to_stage_id == $db.pipeline_stage.id }
      }
      eval = {
        deal_name: $db.deal.name
        user_name: $db.user.name
        stage_name: $db.pipeline_stage.name
      }
      sort = { changed_at: "desc" }
      return = { type: "list", paging: { page: 1, per_page: 18 } }
    } as $feed
  }
  response = $feed
  guid = "_6FlCOZ7c9R2k8v9fbq_Xg5WPtw"
}
