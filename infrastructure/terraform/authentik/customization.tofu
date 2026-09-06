resource "authentik_property_mapping_provider_scope" "mealie" {
  name       = "OAuth Mapping: OpenID 'mealie' (email)"
  scope_name = "email"
  expression = <<EOF
return {
  "email": user.email,
  "email_verified": True,
}
EOF
}
