resource "proxmox_vm_qemu" "kube-master" {
  for_each = var.masters

  name        = each.key
  target_node = each.value.target_node
  agent       = 1
  clone       = "${each.value.target_node}-${var.common.clone}"
  #clone       = var.common.clone
  clone_wait = 0
  vmid       = each.value.id
  memory     = each.value.memory
  cores      = each.value.cores
  vga {
    type = "qxl"
  }
  network {
    model    = "virtio"
    macaddr  = each.value.macaddr
    bridge   = "vmbr911"
    tag      = 924
    firewall = true
  }
  disk {
    type    = "scsi"
    storage = "zfs500blue"
    size    = each.value.disk
    format  = "raw"
    ssd     = 1
    discard = "on"
  }
  serial {
    id   = 0
    type = "socket"
  }
  lifecycle {
    ignore_changes  = [
      network,
    ]
  }
  bootdisk     = "scsi0"
  scsihw       = "virtio-scsi-pci"
  os_type      = var.common.os_type
  ipconfig0    = "ip=${each.value.cidr},gw=${each.value.gw}"
  ciuser       = "ubuntu"
  cipassword   = var.user_password
  searchdomain = var.common.search_domain
  nameserver   = var.common.nameserver
  sshkeys      = var.ssh_pub_key
  # SOPS
  #cipassword   = data.sops_file.secrets.data["k8s.user_password"]
  #sshkeys      = data.sops_file.secrets.data["k3s.ssh_key"]

  connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = var.ssh_key
    host     = each.value.ip
  }

  provisioner "remote-exec" {
    inline = [
      "HISTCONTROL=ignorespace",
      " echo \"${var.user_password}\" | sudo -S -k /bin/bash -c '\"%ubuntu ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/ubuntu'",
      "ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N \"\"",
    ]
  }
}