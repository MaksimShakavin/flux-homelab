# Auto-publish every bucket module's Garage-generated S3 key into a single
# 1Password item so External Secrets can sync them into the cluster. Garage only
# returns the secret at key creation time, so this closes the loop instead of
# copy-pasting Tofu outputs by hand.
#
# ESO's 1Password provider ignores section names and matches fields by label
# only, so field labels must be unique per bucket => bucket-prefixed.
locals {
  bucket_credentials = {
    kopiur         = module.kopiur_bucket
    postgress      = module.postgress_bucket
    terraform      = module.terraform_bucket
    static-content = module.static_content_bucket
    # add one line when a new bucket module is introduced
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
