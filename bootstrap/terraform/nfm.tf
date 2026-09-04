################################################################################
# CloudWatch Network Flow Monitor
#
# The agent addon (see eks.tf) publishes telemetry, but nothing is queryable
# until a scope defines which account/Region is monitored and a monitor defines
# the workload to report on.
################################################################################

# A scope is the account/Region pair whose traffic Network Flow Monitor observes.
# Network Flow Monitor supports a single scope per account, so a second stack in
# the same account and Region will conflict with this resource.
resource "aws_networkflowmonitor_scope" "this" {
  target {
    region = local.region

    target_identifier {
      target_type = "ACCOUNT"

      target_id {
        account_id = data.aws_caller_identity.current.account_id
      }
    }
  }

  tags = local.tags
}

# Scoping local_resource to the cluster reports on flows originating from any
# node in it. Leaving remote_resource unset monitors traffic to all destinations.
resource "aws_networkflowmonitor_monitor" "cluster" {
  monitor_name = local.name
  scope_arn    = aws_networkflowmonitor_scope.this.scope_arn

  local_resource {
    type       = "AWS::EKS::Cluster"
    identifier = module.eks.cluster_arn
  }

  tags = local.tags
}
