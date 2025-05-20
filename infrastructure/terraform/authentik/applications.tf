module "oauth2-grafana" {
  source             = "./oauth2_application"
  name               = "Grafana"
  icon_url           = "https://raw.githubusercontent.com/grafana/grafana/main/public/img/icons/mono/grafana.svg"
  launch_url         = "https://grafana.exelent.click"
  description        = "Infrastructure graphs"
  newtab             = true
  group              = "Infrastructure"
  auth_groups        = [authentik_group.infrastructure.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id
  client_id          = module.secret_grafana.fields["OIDC_CLIENT_ID"]
  client_secret      = module.secret_grafana.fields["OIDC_CLIENT_SECRET"]
  redirect_uris      = ["https://grafana.exelent.click/login/generic_oauth"]
}

module "oauth2-paperless" {
  source             = "./oauth2_application"
  name               = "Paperless"
  icon_url           = "https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/dev/resources/logo/web/svg/Color%20logo%20-%20no%20background.svg"
  launch_url         = "https://paperless.exelent.click"
  description        = "Documents"
  newtab             = true
  group              = "Selfhosted"
  auth_groups        = [authentik_group.infrastructure.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id
  client_id          = module.secret_paperless.fields["OIDC_CLIENT_ID"]
  client_secret      = module.secret_paperless.fields["OIDC_CLIENT_SECRET"]
  redirect_uris      = ["https://paperless.exelent.click/accounts/oidc/authentik/login/callback/"]
}

module "oauth2-audiobookshelf" {
  source             = "./oauth2_application"
  name               = "Audiobookshelf"
  icon_url           = "https://raw.githubusercontent.com/advplyr/audiobookshelf-web/master/static/Logo.png"
  launch_url         = "https://audiobooks.exelent.click"
  description        = "Media player"
  newtab             = true
  group              = "Selfhosted"
  auth_groups        = [authentik_group.users.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id
  client_id          = module.secret_audiobookshelf.fields["OIDC_CLIENT_ID"]
  client_secret      = module.secret_audiobookshelf.fields["OIDC_CLIENT_SECRET"]
  additional_property_mappings = formatlist(authentik_property_mapping_provider_scope.audiobookshelf.id)
  redirect_uris      = ["https://audiobooks.exelent.click/auth/openid/callback", "audiobookshelf://oauth"]
}

module "oauth2-mealie" {
  source             = "./oauth2_application"
  name               = "Mealie"
  icon_url           = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/svg/mealie.svg"
  launch_url         = "https://mealie.exelent.click"
  description        = "Cooking receipts"
  newtab             = true
  group              = "Selfhosted"
  auth_groups        = [authentik_group.users.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id
  client_id          = module.secret_mealie.fields["OIDC_CLIENT_ID"]
  client_secret      = module.secret_mealie.fields["OIDC_CLIENT_SECRET"]
  redirect_uris      = ["https://mealie.exelent.click/login"]
}

module "oauth2-portainer" {
  source             = "./oauth2_application"
  name               = "Portainer"
  icon_url           = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/svg/portainer.svg"
  launch_url         = "https://portainer.exelent.click"
  description        = "Container management UI"
  newtab             = true
  group              = "Infrastructure"
  auth_groups        = [authentik_group.infrastructure.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id
  client_id          = module.secret_portainer.fields["OIDC_CLIENT_ID"]
  client_secret      = module.secret_portainer.fields["OIDC_CLIENT_SECRET"]
  redirect_uris      = ["https://portainer.exelent.click/"]
}

module "oauth2-lubelogger" {
  source             = "./oauth2_application"
  name               = "Lubelogger"
  icon_url           = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/lubelogger.png"
  launch_url         = "https://lubelogger.exelent.click"
  description        = "Vehicle management"
  newtab             = true
  group              = "Selfhosted"
  auth_groups        = [authentik_group.users.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id
  client_id          = module.secret_lubelogger.fields["OIDC_CLIENT_ID"]
  client_secret      = module.secret_lubelogger.fields["OIDC_CLIENT_SECRET"]
  redirect_uris      = ["https://lubelogger.exelent.click/Login/RemoteAuth"]
}

module "oauth2-immich" {
  source             = "./oauth2_application"
  name               = "Immich"
  icon_url           = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/immich.png"
  launch_url         = "https://photos.exelent.click"
  description        = "Self-hosted google photos"
  newtab             = true
  group              = "Selfhosted"
  auth_groups        = [authentik_group.users.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = data.authentik_flow.default-provider-invalidation-flow.id
  client_id          = module.secret_immich.fields["OIDC_CLIENT_ID"]
  client_secret      = module.secret_immich.fields["OIDC_CLIENT_SECRET"]
  redirect_uris      = ["https://photos.exelent.click/auth/login", "app.immich:///oauth-callback", "https://photos.exelent.click/user-settings"]
}
