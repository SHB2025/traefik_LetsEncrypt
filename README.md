🛠️ Automatska Traefik + Let's Encrypt Instalacija

📥 Kako preuzeti i pokrenuti skriptu / How to download and run the script

# VAŽNO: 
    1. Za ispravno funkcionisanje skripta mora biti pokrenuta u korisničkom (user) folderu. Npr. /home/korisnik1/traefik_cloudflare.sh
    2. Kreirajte A ili CNAME rekord za traefik (traefik.vašadomena.com)
# IMPORTANT: 
    1. For proper functioning, the script must be run in the user folder. E.g. /home/user1/traefik_cloudflare.sh
    2. Create an A or CNAME record for traefik (traefik.yourdomain.com)

# Koraci za preuzimanje i izvršavanje skripte (Steps to download and run the script):

    wget https://raw.githubusercontent.com/SHB2025/traefik_cloudflare/refs/heads/main/traefik_cloudflare.sh

    chmod +x Traefik_LetsEncrypt.sh

    sudo ./Traefik_LetsEncrypt.sh



🚀 Automatizirana bash skripta za brzo postavljanje sigurnog Traefik reverse proxy-ja

Opis :

Ova bash skripta omogućava jednostavno i automatizirano postavljanje Traefik reverse proxy-ja sa sljedećim funkcionalnostima:

Potpuno automatsko izdavanje SSL certifikata putem Let's Encrypt.

HTTP/3 podrška, automatski redirect sa HTTP na HTTPS

Zaštićeni pristup Traefik dashboardu putem osnovne autentifikacije (Basic Auth)

Automatsko kreiranje .env, .traefikpasswd, docker-compose.yml i tls.yml fajlova


🧩 Pogodno za:
Samostalne servere (npr. Hetzner, DigitalOcean, Proxmox VM)

Razvojne i produkcijske okoline

🇬🇧 Description (English):
This bash script allows you to quickly and securely set up a Traefik reverse proxy with:

Full Cloudflare DNS API support via CLOUDFLARE_API_TOKEN

Automated Let's Encrypt SSL certificate generation

HTTP/3 support, HTTP to HTTPS redirect

Secured access to Traefik dashboard using Basic Auth

Automatic generation of .env, .traefikpasswd, docker-compose.yml, and tls.yml

🧩 Perfect for:
Self-hosted environments (Hetzner, DigitalOcean, Proxmox VMs, etc.)

Both dev and production use cases
