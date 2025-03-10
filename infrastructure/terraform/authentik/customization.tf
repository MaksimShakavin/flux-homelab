resource "authentik_property_mapping_provider_scope" "audiobookshelf" {
  name       = "OAuth Mapping: OpenID 'audiobookshelf'"
  scope_name = "groups"
  expression = <<EOF
groups = []
existingGroups = [group.name for group in user.ak_groups.all()]
if "Infrastructure" in existingGroups:
  groups.append("admin")
return { "groups": groups }
EOF
}
