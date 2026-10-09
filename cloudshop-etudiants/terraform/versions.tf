terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Backend distant : les valeurs sont fournies par env/<env>.backend.hcl
  #   terraform init -backend-config=env/dev.backend.hcl
  backend "azurerm" {}
}
