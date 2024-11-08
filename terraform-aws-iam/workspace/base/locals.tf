locals {
  cluster_name                  = var.cluster_name
  name                          = local.cluster_name
  region                        = var.region
  environment                   = var.environment
  k8s_service_account_namespace = ""
  k8s_service_account_name      = ""
  cluster_iam_role_name         = ""
  cluster_oidc_issuer_url       = ""
  tags                          = {
    application: local.cluster_name,
    environment: local.environment,
  }
}
