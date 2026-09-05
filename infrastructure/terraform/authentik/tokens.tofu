# Automation service account + the API tokens minted against it. Token keys are
# generated server-side by Authentik (they cannot be supplied), then copied into
# a 1Password item so External Secrets syncs them into the cluster. This replaces
# sharing the admin bootstrap token with in-cluster consumers.

data "onepassword_vault" "homelab" {
  name = "homelab"
}

# Superuser is a group property in Authentik, not a user one. Widgets/consumers
# that need admin read access (version, user/event counts) get it via this group.
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

# --- Tokens ---------------------------------------------------------------
# One authentik_token per consumer; add more blocks + fields below as needed.

resource "authentik_token" "homepage" {
  identifier   = "homepage-widget"
  user         = authentik_user.automation.id
  intent       = "api"
  description  = "Homepage Authentik widget"
  expiring     = false
  retrieve_key = true
}

# ESO's 1Password provider matches fields by label only (section ignored), so
# labels must be globally unique.
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
