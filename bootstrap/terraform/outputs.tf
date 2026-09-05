################################################################################
# Outputs
################################################################################
output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig."
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "nfm_agent_role_arn" {
  description = "IAM role the Network Flow Monitor agent assumes via EKS Pod Identity."
  value       = aws_iam_role.nfm_agent.arn
}

output "nfm_monitor_arn" {
  description = "ARN of the Network Flow Monitor monitor scoped to this cluster."
  value       = aws_networkflowmonitor_monitor.cluster.monitor_arn
}

output "verify_nfm_agent" {
  description = "Confirm the Network Flow Monitor agent pods are running."
  value       = "kubectl get pods -A -l app.kubernetes.io/name=aws-network-flow-monitoring-agent"
}
