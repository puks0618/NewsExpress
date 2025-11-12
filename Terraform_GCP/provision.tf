resource "null_resource" "provision_control_server" {
  depends_on = [
    local_file.ansible_inventory_yml,
    local_file.ansible_all_yml
  ]

  connection {
    type        = "ssh"
    user        = "kaanevran"
    private_key = file("../keys/control-key")
    host        = google_compute_instance.control_instance.network_interface.0.access_config.0.nat_ip
  }


  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/kaanevran/ansible_files"
    ]
  }

  provisioner "file" {
    source      = "../ansible_files/"
    destination = "/home/kaanevran/ansible_files/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod -R 755 /home/kaanevran/ansible_files/",
      "sudo chmod 600 /home/kaanevran/ansible_files/keys/*"
    ]
  }
}



resource "null_resource" "install_ansible" {

  depends_on = [null_resource.provision_control_server]

  connection {
    type        = "ssh"
    user        = "kaanevran"
    private_key = file("../keys/control-key")
    host        = google_compute_instance.control_instance.network_interface.0.access_config.0.nat_ip
  }

  provisioner "remote-exec" {
    inline = [
      #"sudo yum update -y", takes too long for the first run
      "sudo yum update -y ansible",
      "sudo yum install epel-release -y",
      "sudo yum install -y ansible | sudo tee /var/log/ansible_install.log"
    ]
  }
}
