all:
  vars:
    ansible_python_interpreter: /usr/bin/python3

  children:
    kafka:
      hosts:
        kafka:
          ansible_host: ${kafka_server_private_ip}
          ansible_user: kaanevran
          ansible_ssh_private_key_file: ./keys/kfk-key
    producer:
      hosts:
        producer:
          ansible_host: ${producer_server_private_ip}
          ansible_user: kaanevran
          ansible_ssh_private_key_file: ./keys/strm-key         
    consumer:
      hosts:
        consumer:
          ansible_host: ${consumer_server_private_ip}
          ansible_user: kaanevran
          ansible_ssh_private_key_file: ./keys/cnsmr-key


