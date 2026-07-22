// Authenticate by email + password, return a 24h auth token.
query "login" verb=POST {
  api_group = "Auth"
  description = "Log in with email and password; returns an auth token."
  input {
    email email filters=trim|lower
    text password
  }
  stack {
    db.get "user" {
      description = "Look up the user by email to verify the login"
      field_name = "email"
      field_value = $input.email
    } as $user
    precondition ($user != null) {
      error_type = "accessdenied"
      error = "Invalid credentials"
    }
    security.check_password {
      text_password = $input.password
      hash_password = $user.password
    } as $ok
    precondition ($ok == true) {
      error_type = "accessdenied"
      error = "Invalid credentials"
    }
    security.create_auth_token {
      table = "user"
      id = $user.id
      extras = { role: $user.role }
      expiration = 86400
    } as $token
  }
  response = {
    authToken: $token,
    user: { id: $user.id, name: $user.name, email: $user.email, role: $user.role }
  }
  guid = "KCLgBpfbtxxHExH6UGx_dJvJa2I"
}
