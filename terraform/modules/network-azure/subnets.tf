resource "azurerm_subnet" "public" {
  count = "${length(var.network_cidrs_public)}"

  name                 = "${var.network_name}-public-${count.index}"
  resource_group_name  = "${var.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = var.network_cidrs_public[count.index]
}

resource "azurerm_subnet" "private" {
  count = "${length(var.network_cidrs_private)}"

  name                 = "${var.network_name}-private-${count.index}"
  resource_group_name  = "${var.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = var.network_cidrs_private[count.index]
}
