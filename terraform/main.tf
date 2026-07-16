locals {
  repo_path = abspath("${path.module}/..")
}

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

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /opt/docs",
    ]
  }

  provisioner "file" {
    source      = local.repo_path
    destination = "/opt/docs"
  }

  provisioner "remote-exec" {
    inline = [
      "ls -la /opt/docs/",
      "docker compose --version || docker-compose --version",
      "cd /opt/docs && (docker compose up -d 2>/dev/null || docker-compose up -d)",
    ]
  }
}
