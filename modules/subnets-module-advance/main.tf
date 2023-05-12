module "subnets_module_advance" {
  for_each            = var.subnet
  source              = "./subnets-module"
  vpc_id              = var.vpc_id
  region              = var.region_name
  name                = each.key
  subnet_details      = each.value.details
  is_public           = each.value.is_public
  common_tags         = var.common_tags
  project_name_prefix = var.project_name_prefix
}

module "internet_gateway" {
  source = "../internet-gateway"
  vpc_id = var.vpc_id
  tags = merge(var.common_tags, tomap({
    "Name" : "${var.project_name_prefix}-internet-gateway"
  }))
}

module "elastic_ip" {
  source = "../elastic-ip"
  tags = merge(var.common_tags, tomap({
    "Name" : "${var.project_name_prefix}-elastic-ip"
  }))
}

module "nat_gateway1" {
  depends_on    = [module.subnets_module_advance, module.elastic_ip]
  source        = "../nat-gateway"
  allocation_id = module.elastic_ip.eip_id
  subnet_id     = values(lookup(tomap({ for k, bd in module.subnets_module_advance : k => bd.subnet_id }), local.public_subnet_name, {}))[0]
  tags = merge(var.common_tags, tomap({
    "Name" : "${var.project_name_prefix}-nat-gateway"
  }))
}

module "nat_gateway2" {
  depends_on    = [module.subnets_module_advance, module.elastic_ip]
  source        = "../nat-gateway"
  allocation_id = module.elastic_ip.eip_id
  subnet_id     = values(lookup(tomap({ for k, bd in module.subnets_module_advance : k => bd.subnet_id }), local.public_subnet_name, {}))[1]
  tags = merge(var.common_tags, tomap({
    "Name" : "${var.project_name_prefix}-nat-gateway"
  }))
}

module "route_table" {
  depends_on          = [module.internet_gateway]
  for_each            = var.subnet
  source              = "../route-table-module"
  vpc_id              = var.vpc_id
  internet_gateway_id = module.internet_gateway.internet_gateway_id
  nat_gateway_id      = module.nat_gateway.nat_gateway_id
  common_tags         = var.common_tags
  project_name_prefix = var.project_name_prefix
  name                = each.key
  is_public           = each.value.is_public
  nat_gateway         = each.value.nat_gateway
  cidr_block          = "0.0.0.0/0"
}

module "route_table_association" {
  depends_on     = [module.subnets_module_advance, module.route_table]
  for_each       = var.subnet
  source         = "../route-table-association-module"
  subnet_ids     = lookup(tomap({ for k, bd in module.subnets_module_advance : k => bd.subnet_id }), each.key, {})
  route_table_id = lookup(tomap({ for k, bd in module.route_table : k => bd.route_table_id }), each.key, "undefined")
}

module "route_table_peering_routes" {
  source          = "../routes-module"
  count           = var.create_peering_routes ? 1 : 0
  routes          = var.routes
  route_table_ids = tomap({ for k, bd in module.route_table : k => bd.route_table_id })
}
