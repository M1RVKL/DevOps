terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "ubuntu_image" {
  name   = "ubuntu-24.04.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = file("${path.module}/cloud-init.cfg")
  pool      = "default"
}

resource "libvirt_volume" "worker_disk" {
  name           = "worker_disk.qcow2"
  base_volume_id = libvirt_volume.ubuntu_image.id
  pool           = "default"
  size           = 10737418240 # 10 GB
}

resource "libvirt_volume" "db_disk" {
  name           = "db_disk.qcow2"
  base_volume_id = libvirt_volume.ubuntu_image.id
  pool           = "default"
  size           = 10737418240
}

resource "libvirt_domain" "worker_vm" {
  name   = "lab4-worker"
  memory = "1024"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.worker_disk.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

resource "libvirt_domain" "db_vm" {
  name   = "lab4-db"
  memory = "1024"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.db_disk.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

output "worker_ip" {
  value = libvirt_domain.worker_vm.network_interface[0].addresses[0]
}

output "db_ip" {
  value = libvirt_domain.db_vm.network_interface[0].addresses[0]
}