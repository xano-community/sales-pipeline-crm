// The authenticated user's profile (incl. quota).
query "me" verb=GET {
  api_group = "Auth"
  description = "Return the authenticated user's profile."
  auth = "user"
  input {}
  stack {
    db.get "user" {
      description = "Load the authenticated user's own profile record"
      field_name = "id"
      field_value = $auth.id
    } as $user
  }
  response = {
    id: $user.id,
    name: $user.name,
    email: $user.email,
    role: $user.role,
    quota_amount: $user.quota_amount,
    quota_period: $user.quota_period
  }
  guid = "eYCUXGl6lZEZl_LISvF8h7bXD00"
}
