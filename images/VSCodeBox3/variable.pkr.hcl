variable "branch" {
  type    = string
  default = ""
  description = "The branch to use for the build"
}

variable "commit" {
  type    = string
  default = ""
  description = "The commit to use for the build"
}

variable "galleryName" {
  type    = string
  default = ""
  description = "The name of the gallery to use for the build"
}

variable "image" {
  type    = string
  default = ""
  description = "The name of the image to use for the build"
}

variable "location" {
  type    = string
  default = ""
  description = "The location to use for the build"
}

variable "replicaLocations" {
  type    = list(string)
  default = []
  description = "The locations to replicate the image to"
}

variable "resourceGroup" {
  type    = string
  default = ""
  description = "The resource group to use for the managed image"
}

variable "tempResourceGroup" {
  type    = string
  default = ""
  description = "The resource group to use for the build"
}

variable "subscription" {
  type    = string
  default = ""
  description = "The subscription to use for the build"
}

variable "version" {
  type    = string
  default = ""
  description = "The version to use for the build"
}