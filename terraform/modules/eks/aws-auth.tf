# ================================
# AWS Auth ConfigMap for EKS
# ================================

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.main.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.main.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  alias                  = "eks"
}

# Manage aws-auth ConfigMap safely
resource "null_resource" "wait_for_eks" {
  provisioner "local-exec" {
    command = "aws eks wait cluster-active --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
  }
}

resource "kubernetes_config_map" "aws_auth" {
  provider = kubernetes.eks

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = var.jenkins_iam_role_arn  
        username = "jenkins"
        groups   = ["system:masters"]
      },
      {
        rolearn  = aws_iam_role.eks_node_group.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
  }

  lifecycle {
    ignore_changes = [
      
      metadata[0].annotations,
      metadata[0].labels,
      data,
    ]
    prevent_destroy = false
    
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main,
    null_resource.wait_for_eks
  ]
}
