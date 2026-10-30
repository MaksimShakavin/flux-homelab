# Automation service account + its API tokens, so in-cluster consumers don't
# share the admin bootstrap token. Keys are generated server-side by Authentik
# and published to 1Password for ESO to sync.

data "onepassword_vault" "homelab" {
  name = "homelab"
}

# Superuser is a group property in Authentik, not a user one; admin read access
# (version, user/event counts) comes via this group.
resource "authentik_group" "automation" {
  name         = "automation"
  is_superuser = true
}

resource "authentik_user" "automation" {
  username = "svc-automation"
  name     = "Automation Service Account"
  type     = "service_account"
  groups   = [authentik_group.automation.id]
}

resource "authentik_token" "homepage" {
  identifier   = "homepage-widget"
  user         = authentik_user.automation.id
  intent       = "api"
  description  = "Homepage Authentik widget"
  expiring     = false
  retrieve_key = true
}

# ESO matches fields by label (section ignored), so labels must be globally unique.
resource "onepassword_item" "authentik_tokens" {
  vault    = data.onepassword_vault.homelab.uuid
  title    = "authentik-tokens"
  category = "login"

  section {
    label = "tokens"
    field {
      label = "HOMEPAGE_AUTHENTIK_TOKEN"
      type  = "CONCEALED"
      value = authentik_token.homepage.key
    }
  }
}
