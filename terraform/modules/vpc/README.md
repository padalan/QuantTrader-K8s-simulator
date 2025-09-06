# VPC Module

Creates a minimal VPC suitable for learning and hobby environments.

## Inputs

- `project_name` (string): Project tag, default `quanttrader-k8s`
- `environment` (string): Environment tag, default `dev`
- `vpc_cidr` (string): VPC CIDR, default `10.0.0.0/16`
- `availability_zones` (list(string)): AZs, default `["us-west-2a","us-west-2b"]`
- `public_subnet_cidrs` (list(string)): Optional explicit public subnet CIDRs
- `private_subnet_cidrs` (list(string)): Optional explicit private subnet CIDRs
- `enable_nat_gateway` (bool): Create NAT for private subnets, default `false`
- `nat_per_az` (bool): One NAT per AZ (costly), default `false`
- `tags` (map(string)): Additional resource tags

## Outputs

- `vpc_id`: VPC ID
- `public_subnet_ids`: Public subnets
- `private_subnet_ids`: Private subnets
- `internet_gateway_id`: IGW ID
- `nat_gateway_id`: NAT ID (or null)
- `eks_cluster_security_group_id`: EKS control plane SG
- `eks_nodes_security_group_id`: EKS workers SG

## Usage

```hcl
module "vpc" {
  source               = "../../modules/vpc"
  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  nat_per_az           = var.nat_per_az
  tags                 = local.common_tags
}
```

## Topology

- 1 VPC
- 2 Public subnets (map_public_ip_on_launch=true)
- 2 Private subnets
- 1 IGW
- 0 or 1..N NAT (based on flags)
- Route tables for public and private subnets
- Basic SGs for future EKS learning

> Costs: NAT Gateways incur hourly + data processing charges. Keep `enable_nat_gateway=false` for hobby mode.
