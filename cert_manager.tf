resource "helm_release" "cert-manager" {
  name                  = var.release_name
  chart                 = var.chart_name
  repository            = var.chart_repository
  version               = var.chart_version
  namespace             = var.release_namespace
  create_namespace      = true
  wait                  = true
  atomic                = true
  timeout               = 900 // 15 Minutes
  render_subchart_notes = true
  dependency_update     = true
  wait_for_jobs         = true
  dynamic "set" {
    for_each = { for param in var.chart_set_parameter : param.name => {
      value = param.value
      type  = param.type
    } }
    content {
      name  = set.key
      value = set.value.value
      type  = set.value.type
    }
  }
  dynamic "set_list" {
    for_each = { for param in var.chart_set_list_parameter : param.name => param.value }
    content {
      name  = set_list.key
      value = set_list.value
    }
  }
  dynamic "set_sensitive" {
    for_each = {
      "clusterIssuers.otcDNS.accessKey" = opentelekomcloud_identity_credential_v3.user_aksk.access
      "clusterIssuers.otcDNS.secretKey" = opentelekomcloud_identity_credential_v3.user_aksk.secret
    }
    content {
      name  = set_sensitive.key
      value = set_sensitive.value
    }
  }
  dynamic "set_sensitive" {
    for_each = { for param in var.chart_set_sensitive_parameter : param.name => {
      value = param.value
      type  = param.type
    } }
    content {
      name  = set_sensitive.key
      value = set_sensitive.value.value
      type  = set_sensitive.value.type
    }
  }
  values = concat([
    yamlencode({
      clusterIssuers = {
        email = var.email
        otcDNS = {
          region = data.opentelekomcloud_identity_project_v3.current.region
        }
      }
    })
  ], var.chart_values)
}
