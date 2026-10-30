# Publish each bucket's S3 key to 1Password for ESO to sync: Garage only returns
# the secret at creation time. ESO matches fields by label (sections ignored), so
# labels are bucket-prefixed to stay globally unique.
locals {
  bucket_credentials = {
    kopiur         = module.kopiur_bucket
    cnpg           = module.cnpg_bucket
    terraform      = module.terraform_bucket
    static-content = module.static_content_bucket
  }
}

data "onepassword_vault" "homelab" {
  name = "homelab"
}

resource "onepassword_item" "garage_buckets" {
  vault    = data.onepassword_vault.homelab.uuid
  title    = "garage-buckets"
  category = "login"

  dynamic "section" {
    for_each = local.bucket_credentials
    content {
      label = section.key
      field {
        label = "${section.key}_AWS_ACCESS_KEY_ID"
        type  = "STRING"
        value = section.value.access_key_id
      }
      field {
        label = "${section.key}_AWS_SECRET_ACCESS_KEY"
        type  = "CONCEALED"
        value = section.value.secret_access_key
      }
    }
  }
}
