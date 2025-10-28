# Kubernetes provider for EKS cluster
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
    ignore_changes = [data, metadata]
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main
  ]
}
