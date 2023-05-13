data "aws_subnet" "selected" {
  id = var.subnet_id
}
resource "aws_route_table_association" "route_table_association" {
  count          = regex("private-2", lookup(data.aws_subnet.selected.tags, "Name")) == "private-2" ? 0 : 1
  route_table_id = var.route_table_id
  subnet_id      = var.subnet_id
}

resource "aws_route_table_association" "route_table_association2" {
  count          = regex("private-2", lookup(data.aws_subnet.selected.tags, "Name")) == "private-2" ? 1 : 0
  route_table_id = var.route_table_id
  subnet_id      = var.subnet_id
}
