# Configuración de proveedores para múltiples regiones
provider "aws" {
  region     = "us-east-1"  # Región primaria
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_session_token
}

provider "aws" {
  alias      = "us_west_2"
  region     = "us-west-2"  # Región secundaria
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_session_token
}

# Configuración de proveedores para cada región
variable "regions" {
  description = "Map of regions to deploy to"
  type = map(object({
    region = string
    cidr   = string
  }))
  default = {
    "us-east-1" = {
      region = "us-east-1"
      cidr   = "10.0.0.0/16"
    },
    "us-west-2" = {
      region = "us-west-2"
      cidr   = "10.1.0.0/16"
    }
  }
}
