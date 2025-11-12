data "template_file" "all_yml" {
  template = file("../ansible_files/group_vars/all.yml.tpl")

  vars = {
    control_server_public_ip   = google_compute_instance.control_instance.network_interface.0.access_config.0.nat_ip
    kafka_server_private_ip    = google_compute_instance.kafka_instance.network_interface.0.network_ip
    producer_server_private_ip = google_compute_instance.stream_producer_instance.network_interface.0.network_ip
    consumer_server_private_ip = google_compute_instance.consumer_instance.network_interface.0.network_ip
  }
}

data "template_file" "inventory_yml" {
  template = file("../ansible_files/inventory.yml.tpl")

  vars = {
    kafka_server_private_ip    = google_compute_instance.kafka_instance.network_interface.0.network_ip
    producer_server_private_ip = google_compute_instance.stream_producer_instance.network_interface.0.network_ip
    consumer_server_private_ip = google_compute_instance.consumer_instance.network_interface.0.network_ip
  }
}

data "template_file" "producer_defaults_main_yml" {
  template = file("../ansible_files/roles/producer/defaults/main.yml.tpl")

  vars = {
    kafka_server_private_ip = google_compute_instance.kafka_instance.network_interface.0.network_ip
  }
}

data "template_file" "producer_vars_main_yml" {
  template = file("../ansible_files/roles/producer/vars/main.yml.tpl")

  vars = {
    kafka_server_private_ip = google_compute_instance.kafka_instance.network_interface.0.network_ip
    api_key                 = local.secret_key
  }
}

data "template_file" "consumer_defaults_main_yml" {
  template = file("../ansible_files/roles/consumer/defaults/main.yml.tpl")

  vars = {
    temp_bucket_name = google_storage_bucket.temp_bucket.name
    kafka_server_private_ip = google_compute_instance.kafka_instance.network_interface.0.network_ip
  }
}


resource "local_file" "ansible_all_yml" {

  depends_on = [google_compute_instance.control_instance,
    google_compute_instance.kafka_instance,
    google_compute_instance.consumer_instance,
  google_compute_instance.stream_producer_instance]


  content  = data.template_file.all_yml.rendered
  filename = "../ansible_files/group_vars/all.yml"
}

resource "local_file" "ansible_inventory_yml" {

  depends_on = [google_compute_instance.kafka_instance,
    google_compute_instance.stream_producer_instance,
  google_compute_instance.consumer_instance]

  content  = data.template_file.inventory_yml.rendered
  filename = "../ansible_files/inventory.yml"
}

resource "local_file" "ansible_producer_defaults_main_yml" {
  depends_on = [
    google_compute_instance.kafka_instance
  ]

  content  = data.template_file.producer_defaults_main_yml.rendered
  filename = "../ansible_files/roles/producer/defaults/main.yml"
}


resource "local_file" "ansible_producer_vars_main_yml" {

  depends_on = [google_compute_instance.kafka_instance]

  content  = data.template_file.producer_vars_main_yml.rendered
  filename = "../ansible_files/roles/producer/vars/main.yml"

}



resource "local_file" "ansible_consumer_defaults_main_yml" {
  depends_on = [
    google_compute_instance.kafka_instance
  ]

  content  = data.template_file.consumer_defaults_main_yml.rendered
  filename = "../ansible_files/roles/consumer/defaults/main.yml"
}


