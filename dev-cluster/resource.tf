resource "local_file" "kind_config_generator"{
    
    filename = "${path.module}/terraform-generated-${var.cluster_name}-config.yaml"
    content = templatefile("${path.module}/template-kind-config.yaml",{
    cluster_name = var.cluster_name
    
    })
}


resource "null_resource" "kind_cluster_dev" {
    depends_on = [local_file.kind_config_generator]

    triggers = {
        cluster_name = var.cluster_name
    }

    provisioner "local-exec" {
        command = "kind create cluster --config ${local_file.kind_config_generator.filename}"
    }

    provisioner "local-exec" {
        when = destroy
        command = "kind delete cluster --name ${self.triggers.cluster_name}"
    }
}