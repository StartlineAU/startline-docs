resource "digitalocean_droplet" "docs" {
  image      = "docker-20-04"
  name       = "startline-docs"
  region     = "syd1"
  size       = "s-1vcpu-1gb"
  ssh_keys   = ["bc:1d:ac:17:49:8c:3f:3d:97:07:61:ed:8a:ef:f5:18"]
  monitoring = true
  tags       = ["startline", "docs"]

  connection {
    type     = "ssh"
    host     = self.ipv4_address
    user     = "root"
    timeout  = "10m"
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
