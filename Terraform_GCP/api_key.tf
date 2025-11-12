locals {
  env_file_content = file("../.env")
  secret_key       = sensitive(regex("(?m)^NEWS_API_KEY=(.*)$", local.env_file_content)[0])
}