# diplom_sys-22
# Дипломная работа по профессии «Системный администратор» - Сергей Шульга

# Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в Yandex Cloud и отвечать минимальным стандартам безопасности. Для развёртки инфраструктуры используйте Terraform и Ansible.
Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.
Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.
Создайте Target Group, включите в неё две созданных ВМ.
Создайте Backend Group, настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.
Создайте HTTP router. Путь укажите — /, backend group — созданную ранее.
Создайте Application load balancer для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.
Протестируйте сайт curl -v <публичный IP балансера>:80

Terraform

Для начала создадим общую сеть:
```
resource "yandex_vpc_network" "network-main" {
  name = "diplom-net"
}
```
Создадим подсети для размещения серверов:
```
resource "yandex_vpc_subnet" "mysubnet-a" {
  name           = "mysubnet-a"
  v4_cidr_blocks = ["10.5.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-main.id
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_subnet" "mysubnet-b" {
  name           = "mysubnet-b"
  v4_cidr_blocks = ["10.6.0.0/16"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-main.id
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_subnet" "mysubnet-d" {
  name           = "mysubnet-d"
  v4_cidr_blocks = ["10.7.0.0/16"]
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network-main.id
  route_table_id = yandex_vpc_route_table.rt.id
}
```
Опишите в конфигурационном файле параметры ресурсов виртуальных машин, которые необходимо создать (пример):
```
resource "yandex_compute_instance" "nginx1" {
  name        = "web1"
  hostname    = "web1"
  platform_id = "standard-v3"
  zone        = yandex_vpc_subnet.mysubnet-b.zone

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8o41nbel1uqngk0op2"
      size     = 10
    }
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    user-data = "${file("cloud-init.yaml")}"
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.mysubnet-b.id
    }
}
```
yandex_compute_instance — описание ВМ:
name — имя ВМ.
allow_stopping_for_update — разрешение на остановку работы виртуальной машины для внесения изменений.
platform_id — платформа.
zone — зона доступности, в которой будет находиться ВМ.
resources — количество ядер vCPU и объем RAM, доступные ВМ. Значения должны соответствовать выбранной платформе.
boot_disk — настройки загрузочного диска. Укажите идентификатор диска.
network_interface — настройка сети. 
metadata — в метаданных необходимо передать открытый SSH-ключ для доступа на ВМ.
yandex_vpc_network — описание облачной сети.
yandex_vpc_subnet — описание подсети, к которой будет подключена ВМ.

Остальные машины выполняются по образу и подобию первой.

Создайте Target Group, включите в неё две созданных ВМ.
```
resource "yandex_alb_target_group" "target-group" {
  name = "target-group"

  target {
    subnet_id  = yandex_compute_instance.nginx2.network_interface.0.subnet_id
    ip_address = yandex_compute_instance.nginx2.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_compute_instance.nginx1.network_interface.0.subnet_id
    ip_address = yandex_compute_instance.nginx1.network_interface.0.ip_address
  }
}
```
Создайте Backend Group, настройте backends на target group, ранее созданную, настройте healthcheck на корень (/) и порт 80, протокол HTTP.:

```
resource "yandex_alb_backend_group" "test-backend-group" {
  name = "test-backend-group"
  session_affinity {
    connection {
      source_ip = false
    }
  }

  http_backend {
    name             = "http-backend"
    weight           = 1
    port             = 80
    target_group_ids = ["${yandex_alb_target_group.target-group.id}"]
    load_balancing_config {
      panic_threshold = 9
    }
    healthcheck {
      timeout             = "5s"
      interval            = "2s"
      healthy_threshold   = 2
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}
```
Создайте HTTP router. Путь укажите — /, backend group — созданную ранее.
```
esource "yandex_alb_http_router" "http-router" {
  name = "http-router"
  labels = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }
}

resource "yandex_alb_virtual_host" "virtual-host" {
  name           = "virtual-host"
  http_router_id = yandex_alb_http_router.http-router.id
  route {
    name = "http-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.test-backend-group.id
        timeout          = "3s"
      }
    }
  }
}
```
Создайте Application load balancer для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.
```
resource "yandex_alb_load_balancer" "test-balancer" {
  name               = "test-balancer"
  network_id         = yandex_vpc_network.network-main.id
  security_group_ids = [yandex_vpc_security_group.test-balancer.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.mysubnet-a.id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.mysubnet-b.id
    }
  }

  listener {
    name = "lsnrport"
    endpoint {
      address {
        external_ipv4_address {
          address = yandex_vpc_address.vpc-address.external_ipv4_address[0].address
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.http-router.id
      }
    }
  }
}
```
Ansible

с помощью Ansible на виртуальные машины web1 и web2 установим NGINX





