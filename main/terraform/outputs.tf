output "public_ip_bastion_host" {
  value = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "public_ip_zabbix" {
  value = yandex_compute_instance.zabbix.network_interface[0].nat_ip_address
}

output "private_ip_connect_ssh_vm1" {
  value = yandex_compute_instance.vm1.network_interface[0].ip_address
}

output "private_ip_connect_ssh_vm2" {
  value = yandex_compute_instance.vm2.network_interface[0].ip_address
}

output "public_ip_kibana" {
  value = yandex_compute_instance.kibana.network_interface[0].nat_ip_address
}

output "private_ip_connect_ssh_elasticsearch" {
  value = yandex_compute_instance.elasticsearch.network_interface[0].ip_address
}
output "public_ip_load_balancer" {
  value = yandex_alb_load_balancer.load-balancer.listener[0].endpoint[0].address[0].external_ipv4_address
}

