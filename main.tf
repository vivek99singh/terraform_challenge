#terraform {
#  backend "azurerm" {
#  }
#}
#Create resource group
resource "azurerm_resource_group" "dev" {
  name     = var.resource_group
  location = var.location
}

#create application insight for webappapi
resource "azurerm_application_insights" "webappai1" {
  name                = var.appinsight1
  location            = var.location
  resource_group_name = azurerm_resource_group.dev.name
  application_type    = "web"
}

output "webapp_key1" {
  value = azurerm_application_insights.webappai1.instrumentation_key
}

output "webapp_id1" {
  value = azurerm_application_insights.webappai1.app_id
}

# Create azure application service plan for webapps

resource "azurerm_app_service_plan" "dev1" {
  name                = var.appserviceplan1
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

# Create azure Webapp 1
resource "azurerm_app_service" "webapp1" {
  name                = var.webapp1
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  app_service_plan_id = azurerm_app_service_plan.dev1.id
  https_only          = "true"

  site_config {
    always_on                 = "true"
    ftps_state                = "FtpsOnly"
    #dotnet_framework_version  = "v4.0"
    http2_enabled             = "true"
    min_tls_version           = "1.2"
    use_32_bit_worker_process = "false"
    default_documents = ["Default.htm","Default.html","Default.asp","index.htm","index.html","iisstart.htm","default.aspx","index.php","hostingstart.html"]
  }

  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION = "10.15.2"
    ApiUrl = "/api/v1"
    ApiUrlShoppingCart = "/api/v1"
    MongoConnectionString = "mongodb://40.127.225.246:27020"
    SqlConnectionString = "Server=tcp:productdbsql.database.windows.net,1433;Initial Catalog=productdb;Persist Security Info=False;User ID=adminsql;Password=Admin5ql@123456;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    productImagesUrl = "https://raw.githubusercontent.com/microsoft/TailwindTraders-Backend/master/Deploy/tailwindtraders-images/product-detail"
    Personalizer__ApiKey = ""
    Personalizer__Endpoint = ""
  }

}

resource "azurerm_sql_server" "sql_server" {
  name                         = "productdbsql"
  resource_group_name          = azurerm_resource_group.dev.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = "adminsql"
  administrator_login_password = "Admin5ql@123456"
}
resource "azurerm_sql_firewall_rule" "sql_firewall" {
  name                = "AllowAccessToAzure"
  resource_group_name = azurerm_resource_group.dev.name
  server_name         = azurerm_sql_server.sql_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
resource "azurerm_sql_database" "sql_database" {
  name                = "productdb"
  resource_group_name = azurerm_resource_group.dev.name
  location            = var.location
  server_name         = azurerm_sql_server.sql_server.name
}

resource "azurerm_container_group" "example" {
  name                = "shoppingcartdb"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  ip_address_type     = "public"
  dns_name_label      = "shoppingcartdb"
  os_type             = "Linux"

  container {
    name   = "shoppingcartdb"
    image  = "mongo:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 27017
      protocol = "TCP"
    }
  }
}