variable "branch" {
  type        = string
  default     = ""
  description = "The branch to use for the build"
}

variable "commit" {
  type        = string
  default     = ""
  description = "The commit to use for the build"
}

variable "galleryName" {
  type        = string
  default     = ""
  description = "The name of the gallery to use for the build"
}

variable "galleryResourceGroup" {
  type        = string
  default     = ""
  description = "The resource group to use for the managed image"
}

variable "name" {
  type        = string
  default     = ""
  description = "The name of the image to use for the build"
}

variable "replicaLocations" {
  type        = list(string)
  default     = []
  description = "The locations to replicate the image to"
}

variable "resolvedResourceGroup" {
  type        = string
  default     = ""
  description = ""
}

variable "location" {
  type        = string
  default     = ""
  description = "Azure datacenter in which your VM will build, if this is provided buildResourceGroup should be left blank"
}

variable "tempResourceGroup" {
  type        = string
  default     = ""
  description = "Name assigned to the temporary resource group created during the build. If this value is not set, a random value will be assigned. This resource group is deleted at the end of the build. If this is provided buildResourceGroup should be left blank"
}

variable "buildResourceGroup" {
  type        = string
  default     = ""
  description = "Specify an existing resource group to run the build in. If this is provided tempResourceGroup and location should not be provided"
}

variable "subscription" {
  type        = string
  default     = ""
  description = "The subscription to use for the build"
}

variable "version" {
  type        = string
  default     = ""
  description = "The version to use for the build"
}

variable "identities" {
  type        = list(string)
  default     = []
  description = "One or more fully-qualified resource IDs of user assigned managed identities to be configured on the VM"
}

variable "repos" {
  type = list(object({
    url    = string
    secret = string
  }))
  default     = []
  description = "The repositories to clone on the image"
}