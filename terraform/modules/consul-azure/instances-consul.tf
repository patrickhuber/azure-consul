resource "azurerm_virtual_machine" "consul" {
  count = "${var.cluster_size}"

  name                  = "${var.consul_datacenter}-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = [azurerm_network_interface.consul.*.id[count.index]]
  vm_size               = "${var.vm_size}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.consul_datacenter}-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.consul_datacenter}-${count.index}"
    admin_username = "${module.images.os_user}"
    admin_password = "none"
    custom_data    = "${base64encode(data.template_file.init.rendered)}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${module.images.os_user}/.ssh/authorized_keys"
      key_data = "${var.public_key_data}"
    }
  }

  tags = {
    consul_datacenter = "${var.consul_datacenter}"
  }
}

resource "azurerm_network_interface" "consul" {
  count = "${var.cluster_size}"

  name                = "${var.consul_datacenter}-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "${var.consul_datacenter}-${count.index}"
    subnet_id                     = var.private_subnet_ids[count.index]
    private_ip_address_allocation = "dynamic"
  }

  tags = {
    consul_datacenter = "${var.consul_datacenter}"
  }
}

data "template_file" "init" {
  template = "${file("${path.module}/init-cluster.tpl")}"

  vars = {
    cluster_size                = "${var.cluster_size}"
    consul_version              = "${var.consul_version}"
    consul_datacenter           = "${var.consul_datacenter}"
    consul_join_wan             = "${join(" ", var.consul_join_wan)}"
    auto_join_subscription_id   = "${var.auto_join_subscription_id}"
    auto_join_tenant_id         = "${var.auto_join_tenant_id}"
    auto_join_client_id         = "${var.auto_join_client_id}"
    auto_join_secret_access_key = "${var.auto_join_client_secret}"
  }
}
