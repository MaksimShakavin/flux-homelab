terraform {
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
    }
  }
}

data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

data "authentik_property_mapping_provider_scope" "scopes" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile",
    "goauthentik.io/providers/oauth2/scope-offline_access"
  ]
}

resource "random_password" "client_secret" {
  length = 52
}

resource "authentik_provider_oauth2" "oauth2-application" {
  name                       = var.name
  client_id                  = var.client_id
  client_secret              = local.client_secret
  authorization_flow         = var.authorization_flow
  invalidation_flow          = var.invalidation_flow
  signing_key                = data.authentik_certificate_key_pair.generated.id
  client_type                = var.client_type
  property_mappings          = concat(data.authentik_property_mapping_provider_scope.scopes.ids, var.additional_property_mappings)
  allowed_redirect_uris = [
    for url in var.redirect_uris :
    {
      matching_mode = "strict",
      url           = url,
    }
  ]
}

resource "authentik_application" "oauth2-application" {
  name              = var.name
  slug              = lower(var.name)
  group             = var.group
  protocol_provider = authentik_provider_oauth2.oauth2-application.id
  meta_icon         = var.icon_url
  meta_description  = var.description
  meta_launch_url   = var.launch_url
  open_in_new_tab   = var.newtab
}

resource "authentik_policy_binding" "oauth2-application" {
  target = authentik_application.oauth2-application.uuid
  group  = var.auth_groups[count.index]
  order  = count.index
  count  = length(var.auth_groups)
}
