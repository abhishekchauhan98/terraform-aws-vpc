data "aws_subnet" "selected" {
  id = var.subnet_id
}

resource "aws_route_table_association" "route_table_association2" {
  count          = can(regex("private-2", lookup(data.aws_subnet.selected.tags, "Name"))) ? 1 : 0
  route_table_id = var.route_table_id
  subnet_id      = var.subnet_id
}