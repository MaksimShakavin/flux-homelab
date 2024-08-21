resource "authentik_group" "infrastructure" {
  name         = "Infrastructure"
  is_superuser = false
}
