provider "azurerm" {
  features {}
}

module "resource_group" {
  source      = "git@github.com:pankajyadavdevops/terraform-azure-resource-group.git?ref=v1.0.2"
  version     = "1.0.2"
  name        = "app"
  environment = "test"
  location    = "North Europe"
}

#Vnet
module "vnet" {
  source                 = "git@github.com:pankajyadavdevops/terraform-azure-vnet.git?ref=v1.0.2"
  version                = "1.0.2"
  name                   = "app"
  environment            = "test"
  resource_group_name    = module.resource_group.resource_group_name
  location               = module.resource_group.resource_group_location
  address_space          = "10.0.0.0/16"
  enable_ddos_pp         = false
  enable_network_watcher = false
}

module "subnet" {
  source               = "git@github.com:pankajyadavdevops/terraform-azure-subnet.git?ref=v1.0.2"
  version              = "1.0.2"
  name                 = "app"
  environment          = "test"
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = join("", module.vnet[*].name)

  #subnet
  subnet_names    = ["subnet1"]
  subnet_prefixes = ["10.0.1.0/24"]

  # route_table
  enable_route_table = true
  route_table_name   = "default_subnet"
  routes = [
    {
      name           = "rt-test"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]
}

#Key Vault
module "vault" {
  source                      = "./../.."
  name                        = "app"
  environment                 = "test"
  sku_name                    = "standard"
  principal_id                = ["xxxxxxxxxxxxxxxxxxxxxxxxx"]
  role_definition_name        = ["Key Vault Administrator"]
  resource_group_name         = module.resource_group.resource_group_name
  subnet_id                   = module.subnet.default_subnet_id
  virtual_network_id          = module.vnet.id
  enable_private_endpoint     = true
  enable_rbac_authorization   = true
  purge_protection_enabled    = false
  enabled_for_disk_encryption = true

  depends_on = [module.resource_group, module.vnet]
}

