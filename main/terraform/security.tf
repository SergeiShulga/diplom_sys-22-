resource "yandex_vpc_security_group" "balancer" {
  name        = "balancer public"
  description = "Разрешение на подключение к alb из сети Инертнет по HHTP (80)"
  network_id  = yandex_vpc_network.network-main.id
  
  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "allow HTTP connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "Health checks"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    predefined_target = "loadbalancer_healthchecks"
    port              = 30000
  }
  
}

resource "yandex_vpc_security_group" "inside" {
  name        = "inside"
  description = "Без ограничений внутри подсетей"
  network_id  = yandex_vpc_network.network-main.id
  ingress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "bastion" {
  name        = "bastion public"
  description = "Разрешение на подключение к ВМ bastion по SSH из сети Интернет"
  network_id  = yandex_vpc_network.network-main.id
  
  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    protocol       = "TCP"
    description    = "allow SSH connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "yandex_vpc_security_group" "kibana" {
  name        = "kibana public"
  description = "Разрешение на подключение к kibana из сети Интернет"
  network_id  = yandex_vpc_network.network-main.id
  
    egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    protocol       = "TCP"
    description    = "allow kibana connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol       = "TCP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
}

resource "yandex_vpc_security_group" "zabbix" {
  name        = "zabbix public"
  description = "Разрешение на подключение к zabbix из сети Интернет"
  network_id  = yandex_vpc_network.network-main.id
  
  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    protocol       = "TCP"
    description    = "allow zabbix connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8080
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix-agent"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10050
  }
   ingress {
    protocol       = "TCP"
    description    = "zabbix-agent"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10051
  }
}

