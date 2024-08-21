## Authorization flow
resource "authentik_flow" "provider-authorization-implicit-consent" {
  name               = "Authorize Application"
  title              = "Redirecting to %(app)s"
  slug               = "provider-authorization-implicit-consent"
  policy_engine_mode = "any"
  denied_action      = "message_continue"
  designation        = "authorization"
#  background         = "https://static.${module.secret_authentik.fields["CLUSTER_DOMAIN"]}/branding/Background.jpeg"
}
