resource "digitalocean_droplet" "docs" {
  image  = "docker-20-04"
  name   = "startline-docs"
  region = "syd1"
  size   = "s-1vcpu-1gb"

  ssh_keys = []

  monitoring = true

  tags = ["startline", "docs"]

  connection {
    type = "ssh"
    host = self.ipv4_address
    user = "root"
  }

  provisioner "file" {
    source      = "${path.module}/.."
    destination = "/opt/docs"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/docs && docker compose up -d",
    ]
  }
}
