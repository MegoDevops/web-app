[jenkins]
${jenkins_ip} ansible_ssh_private_key_file=${key_path}

[all:vars]
ansible_user=ubuntu
ansible_python_interpreter=/usr/bin/python3
