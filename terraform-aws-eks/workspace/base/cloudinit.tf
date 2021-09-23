//data "template_file" "eks-main-bastion-init" {
//  template = file("../../scripts/eks-main-bastion-init.sh")
//  vars = {
//    DEVICE            = var.INSTANCE_DEVICE_NAME
//  }
//}
//
//data "template_cloudinit_config" "eks-main-bastion-cloudinit" {
//  gzip          = false
//  base64_encode = false
//
//  part {
//    content_type = "text/x-shellscript"
//    content      = data.template_file.eks-main-bastion-init.rendered
//  }
//}
//
