output "kind_config_file" {
  value       = local_file.kind_config_generator.filename
  description = "Path to the generated Kind configuration file"
}

output "kubectl_context" {
  value       = "kind-${var.cluster_name}"
  description = "Kubectl context name for the created Kind cluster"
}