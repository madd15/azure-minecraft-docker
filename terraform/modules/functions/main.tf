locals {
  app_service_settings         = {
    APPINSIGHTS_INSTRUMENTATIONKEY = var.appinsights_instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = "InstrumentationKey=${var.appinsights_instrumentation_key}"
    MINECRAFT_FQDN             = var.minecraft_fqdn
    MINECRAFT_PORT             = var.minecraft_port
    FUNCTIONS_WORKER_RUNTIME   = "dotnet"
    # WEBSITE_CONTENTSHARE       = "${var.resource_group_name}-ping-test-content"
    # WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.functions.name};AccountKey=${azurerm_storage_account.functions.primary_access_key};EndpointSuffix=core.windows.net"
  }
}

resource azurerm_storage_account functions {
  name                         = lower(substr(replace(var.function_name,"/a|e|i|o|u|y|-/",""),0,24))
  resource_group_name          = var.resource_group_name
  location                     = var.location
  account_tier                 = "Standard"
  account_replication_type     = "LRS"

  tags                         = var.tags
}

resource azurerm_function_app ping_test {
  name                         = var.function_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  app_service_plan_id          = var.app_service_plan_id
  app_settings                 = local.app_service_settings
  https_only                   = true
  storage_account_name         = azurerm_storage_account.functions.name
  storage_account_access_key   = azurerm_storage_account.functions.primary_access_key
  version                      = "~4"

  lifecycle {
    ignore_changes             = [
      # Ignore Visual Studio Code modifications
                                 app_settings["WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"], 
                                 app_settings["WEBSITE_CONTENTSHARE"], 
                                 os_type
    ]
  }  

  tags                         = var.tags
}

resource azurerm_monitor_diagnostic_setting function_logs {
  name                         = "Function_Logs"
  target_resource_id           = azurerm_function_app.ping_test.id
  log_analytics_workspace_id   = var.log_analytics_workspace_resource_id

  log {
    category                   = "FunctionAppLogs"
    enabled                    = true

    retention_policy {
      enabled                  = false
    }
  }
  metric {
    category                   = "AllMetrics"

    retention_policy {
      enabled                  = false
    }
  }
}