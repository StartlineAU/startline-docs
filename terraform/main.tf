resource "digitalocean_droplet" "docs" {
  image  = "docker-20-04"
  name   = "startline-docs"
  region = "syd1"
  size   = "s-1vcpu-1gb"

  monitoring = true

  tags = ["startline", "docs"]
}
