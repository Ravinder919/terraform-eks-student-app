provider "aws" {
  region = "us-west-1"
}

data "aws_eks_cluster" "this" {
  name = "terra-cluster"
}

data "aws_eks_cluster_auth" "this" {
  name = "terra-cluster"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.this.certificate_authority[0].data
  )
  token = data.aws_eks_cluster_auth.this.token
}

resource "kubernetes_manifest" "all" {
  for_each = fileset("${path.module}/manifests", "*.yaml")

  manifest = merge(
    yamldecode(file("${path.module}/manifests/${each.value}")),
    {
      metadata = merge(
        try(yamldecode(file("${path.module}/manifests/${each.value}")).metadata, {}),
        {
          namespace = "default"
        }
      )
    }
  )
}