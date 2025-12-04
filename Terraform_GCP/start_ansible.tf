resource "null_resource" "start_ansible" {
  depends_on = [
    null_resource.install_ansible
  ]

  connection {
    type        = "ssh"
    user        = "jey"
    private_key = file("../keys/control-key")
    host        = google_compute_instance.control_instance.network_interface.0.access_config.0.nat_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/jey/ansible_files",
      "ansible-playbook -i inventory.yml playbook.yml"
    ]
  }
}
