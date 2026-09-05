resource "authentik_group" "users" {
  name         = "users"
  is_superuser = false
}

resource "authentik_group" "infrastructure" {
  name         = "Infrastructure"
  is_superuser = false
}
