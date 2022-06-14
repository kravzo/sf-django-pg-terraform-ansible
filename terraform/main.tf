
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.61.0"
    }
  }
    backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "tf-state-bucket-mentor"
    region     = "ru-central1-a"
    key        = "issue1/lemp.tfstate"
    access_key = ""
    secret_key = ""

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "yandex" {
  token                    = ""
  cloud_id                 = "b1g13chgkreor1t4t0ia"
  folder_id                = "b1g7sm1qlqqep588q2lb"
  zone                     = "ru-central1-a"
}

resource "yandex_vpc_network" "network" {
  name = "network"
}

resource "yandex_vpc_subnet" "subnet1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}


module "vm_1" {
  instance_name		= "kube-master"
  source                = "./modules/instance"
  instance_family_image = "ubuntu-2004-lts"
  vpc_subnet_id         = yandex_vpc_subnet.subnet1.id
  nat                   = true
}

module "vm_2" {
  instance_name		= "kube-app"
  source                = "./modules/instance"
  instance_family_image = "ubuntu-2004-lts"
  vpc_subnet_id         = yandex_vpc_subnet.subnet1.id
  nat                   = true
}

module "vm_3" {
  instance_name		= "srv"
  source                = "./modules/instance"
  instance_family_image = "ubuntu-2004-lts"
  vpc_subnet_id         = yandex_vpc_subnet.subnet1.id
  nat                   = true
}

resource "yandex_lb_target_group" "front_tg" {
  name = "front-tg"
  target {
    subnet_id = "${module.vm_2.subnet_id_vm}"
    address = "${module.vm_2.internal_ip_address_vm}"
  }
}

resource "yandex_lb_network_load_balancer" "front-balancer" {
  name = "my-network-load-balancer"

  listener {
    name = "http-listener"
    port = 80
    target_port = 31080
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  listener {
    name = "https-listener"
    port = 443
    target_port = 31443
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.front_tg.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 31080
        path = "/"
      }
    }
  }
}

data "template_file" "ansible_inventory" {
  template = file("./inventory.ini.tpl")
  vars = {
    vm1_internal_ip  = "${module.vm_1.internal_ip_address_vm}"
    vm2_internal_ip  = "${module.vm_2.internal_ip_address_vm}"
    vm3_external_ip  = "${module.vm_3.external_ip_address_vm}"
  }
}

resource "null_resource" "update_inventory" {
 triggers = {
    template = data.template_file.ansible_inventory.rendered
  }
  provisioner "local-exec" {
    command = "echo '${data.template_file.ansible_inventory.rendered}' > ../inventory.ini"
  }
}

data "template_file" "kuber_inventory" {
  template = file("./kuber_inventory.ini.tpl")
  vars = {
    vm1_internal_ip  = "${module.vm_1.internal_ip_address_vm}"
    vm2_internal_ip  = "${module.vm_2.internal_ip_address_vm}"
  }
}

resource "null_resource" "update_kuber_inventory" {
 triggers = {
    template = data.template_file.kuber_inventory.rendered
  }
  provisioner "local-exec" {
    command = "echo '${data.template_file.kuber_inventory.rendered}' > ../kuber_inventory.ini"
  }
}





