metadata_dir = "/metadata"
data_dir = "/data"

replication_factor = 1

rpc_bind_addr = "[::]:3901"
rpc_secret = "${rpc_secret}"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"

[admin]
api_bind_addr = "[::]:3903"
admin_token = "${admin_token}"
