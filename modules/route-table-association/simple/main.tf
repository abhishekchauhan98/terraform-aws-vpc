data "aws_subnet" "selected" {
  id = var.subnet_id
}
resource "aws_route_table_association" "route_table_association" {
  count          = can(regex("private-2", lookup(data.aws_subnet.selected.tags, "Name"))) ? 0 : 1
  route_table_id = var.route_table_id
  subnet_id      = var.subnet_id
}
