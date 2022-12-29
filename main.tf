locals {
  base_domain      = "tools-dev.camptocamp.com"
  cluster_issuer   = "letsencrypt-staging"
  cluster_name     = "mycluster"
  argocd_namespace = "argocd"
}

provider "kubernetes" {
  alias = "green"

  config_path    = "~/.kube/config"
  config_context = "my-context"
}

provider "helm" {
  alias = "green"

  kubernetes {
    config_path = "~/.kube/config"
  }
}



# provider "helm" {
#   alias = "green"

#   kubernetes {
#     host                   = local.kubernetes_host
#     username               = local.kubernetes_username
#     password               = local.kubernetes_password
#     client_certificate     = local.kubernetes_client_certificate
#     client_key             = local.kubernetes_client_key
#     cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
#   }
# }

# provider "kubernetes" {
#   alias = "green"

#   host                   = local.kubernetes_host
#   username               = local.kubernetes_username
#   password               = local.kubernetes_password
#   client_certificate     = local.kubernetes_client_certificate
#   client_key             = local.kubernetes_client_key
#   cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
# }

########################################
# ArgoCD for bootstrapping Devops Stack
#

module "argocd_bootstrap" {

  # bootstrap require only this provider
  providers = {
    helm = helm.green
  }

  #source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap"
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap?ref=bootstrap_minimal"
  #source = "../../is/devops-stack-module-argocd/bootstrap"

}

provider "argocd" {
  alias = "green"

  server_addr                 = "dummyValue"
  auth_token                  = module.argocd_bootstrap.argocd_auth_token # pipeline token
  insecure                    = true
  plain_text                  = true
  port_forward                = true
  port_forward_with_namespace = "argocd"

  kubernetes {
    config_path = "~/.kube/config"
  }
}


module "cert-manager" {
  providers = {
    argocd = argocd.green
  }

  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git"

  base_domain      = local.base_domain
  cluster_name     = local.cluster_name
  argocd_namespace = local.argocd_namespace

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

# module "loki-stack" {
#   providers = {
#     argocd = argocd.green
#   }

#   #source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack.git//k3s"
#   source = "../../is/devops-stack-module-loki-stack"

#   base_domain         = local.base_domain
#   cluster_name        = local.cluster_name
#   argocd_namespace    = local.argocd_namespace

#   # depends_on = [
#   #   module.prometheus-stack # CRD dependency
#   # ]
# }


module "prometheus-stack" {
  #count = local.clusters["green"].apps_enabled ? 1 : 0

  providers = {
    argocd = argocd.green
  }

  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git"
  #source = "../devops-stack-module-kube-prometheus-stack/aks"

  base_domain      = local.base_domain
  cluster_name     = local.cluster_name
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = local.argocd_namespace

  #  metrics_archives = module.thanos.metrics_archives

  prometheus = {
    oidc = {
      client_secret = ""
    }
  }
  alertmanager = {
    #oidc = local.oidc
  }
  grafana = {
    # enable = false # Optional
    #additional_data_sources = true
  }

  depends_on = [module.argocd_bootstrap[0].id]
}

#module "argocd" {
#  providers = {
#    argocd = argocd.green
#  }
#
#  source = "../../is/devops-stack-module-argocd"
#  #source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git"
#  #source = "../devops-stack-module-argocd"
#
#  base_domain    = local.base_domain
#  cluster_name   = local.cluster_name
#  cluster_issuer = local.cluster_issuer
#
#  argocd = {
#    namespace                = "argocd"
#    domain                   = "argocd.apps.${local.cluster_name}.${local.base_domain}"
#    accounts_pipeline_tokens = module.argocd_bootstrap.argocd_auth_token # see *1
#    server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
#    admin_enabled            = "true"
#  }
#
#  # *1 this generates in value files something different from what we had before:
#  #
#  #  accounts.pipeline.tokens: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE2NzE2NDE2ODgsImlzcyI6ImFyZ29jZCIsImp0aSI6IjIxZWMzNTVjLTI5YzktODM4OC0wODFhLTE1NWVlYjYzYjJkYSIsIm5iZiI6MTY3MTY0MTY4OCwic3ViIjoicGlwZWxpbmUifQ.cG8I_smbGub0OLRvU79MhqqGEva6VVQdhJpGQj7EEwM
#  #  vs 
#  #  accounts.pipeline.tokens: '[{"iat":1658306871,"id":"d72d7481-45f3-5382-d195-500cdc3a16e8"}]'
#  #  ?
#
#
#  oidc = {
#    clientSecret = "test"
#    # name            = "OIDC"
#    # issuer          = "" #local.oidc.issuer_url
#    # clientID        = "" #local.oidc.client_id
#    # clientSecret    = "" #local.oidc.client_secret
#    # requestedScopes = ["openid", "profile", "email"]
#    # requestedIDTokenClaims = {
#    #   groups = {
#    #     essential = true
#    #   }
#    # }
#  }
#
#  depends_on = [module.argocd_bootstrap.id]
#}
