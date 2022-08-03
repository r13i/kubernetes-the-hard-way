variable "kubernetes_certificate_body_filename" {
  default = "kubernetes.pem"
}

variable "kubernetes_certificate_key_filename" {
  default = "kubernetes-key.pem"
}

variable "ca_certificate_body_filename" {
  default = "ca.pem"
}

resource "aws_acm_certificate" "kubernetes_certificate" {
  count = (
    fileexists("${path.root}/certificates/${var.kubernetes_certificate_body_filename}") &&
    fileexists("${path.root}/certificates/${var.kubernetes_certificate_key_filename}") &&
    fileexists("${path.root}/certificates/${var.ca_certificate_body_filename}")
  ) ? 1 : 0

  certificate_body  = file("${path.root}/certificates/${var.kubernetes_certificate_body_filename}")
  private_key       = file("${path.root}/certificates/${var.kubernetes_certificate_key_filename}")
  certificate_chain = file("${path.root}/certificates/${var.ca_certificate_body_filename}")
}