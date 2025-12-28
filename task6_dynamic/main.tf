variable "dynamic_value" {
  type    = any
  default = null
}

output "value_received" {
  value = var.dynamic_value
}
