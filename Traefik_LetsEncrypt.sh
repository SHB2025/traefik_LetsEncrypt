#!/bin/bash
set -e

# Provjera korisničkih prava
if [[ "$EUID" -ne 0 ]]; then
  echo "Greška: Skripta zahtijeva root prava. Ponovno pokretanje sa sudo..."
  exec sudo "$0" "$@"
fi

# Funkcija za siguran unos povjerljivih podataka sa prikazom zvjezdica
secure_read() {
  local prompt="$1"
  local var_name="$2"
  local input=""

  echo -n "$prompt"
  while IFS= read -r -s -n 1 char; do
    if [[ $char == $'\0' ]]; then
      break
    fi
    if [[ $char == $'\177' ]]; then
      if [[ -n $input ]]; then
        input="${input%?}"
        printf '\b \b'
      fi
    else
      input+="$char"
      printf '*'
    fi
  done
  echo
  eval "$var_name='$input'"
}

# Pita korisnika za sve potrebne varijable
read -p "Unesite vašu email adresu za Let's Encrypt: " LETSENCRYPT_EMAIL
read -p "Unesite naziv domene za Traefik: " DOMAIN_NAME
secure_read "Unesite korisničko ime za osnovnu autentifikaciju: " AUTH_USER
secure_read "Unesite lozinku za osnovnu autentifikaciju: " AUTH_PASSWORD

# Validacija unosa
for var in LETSENCRYPT_EMAIL DOMAIN_NAME AUTH_USER AUTH_PASSWORD; do
  if [[ -z "${!var}" ]]; then
    echo "Greška: Svi unosi su obavezni."
    exit 1
  fi
done

# Kreiranje traefik direktorija
mkdir -p traefik

# Provjera i instalacija htpasswd alata
if ! command -v htpasswd &> /dev/null; then
  echo "htpasswd alat nije pronađen. Instalacija..."
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt-get update
    sudo apt-get install apache2-utils -y
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install httpd
  else
    echo "Greška: Nije podržana platforma za automatsku instalaciju htpasswd alata."
    exit 1
  fi
fi

# Generisanje hashed korisnika i kreiranje hash fajla
HASHED_USER=$(htpasswd -nb "$AUTH_USER" "$AUTH_PASSWORD")
echo "$HASHED_USER" > traefik/.traefikpasswd

# Provjera kreiranja .traefikpasswd fajla
if [[ ! -f "traefik/.traefikpasswd" ]]; then
  echo "Greška: .traefikpasswd fajl nije kreiran."
  exit 1
else
  echo "Fajl .traefikpasswd kreiran uspješno."
fi

# Generisanje .env fajla za Traefik
cat <<EOF > traefik/.env
DOMAIN_NAME="$DOMAIN_NAME"
LETSENCRYPT_EMAIL="$LETSENCRYPT_EMAIL"
HOST_NAME="$DOMAIN_NAME"
EOF

# Provjera kreiranja .env fajla
if [[ ! -f "traefik/.env" ]]; then
  echo "Greška: .env fajl nije kreiran."
  exit 1
else
  echo ".env fajl kreiran uspješno."
fi

# Kreiranje potrebnih direktorija
mkdir -p traefik/data/configurations traefik/certificates
echo "Direktoriji kreirani uspješno."

# Kreiranje docker-compose.yml fajla
cat <<EOF > traefik/docker-compose.yml
networks:
  traefik:
    external: true
    name: traefik

services:
  traefik:
    container_name: traefik
    image: traefik:latest
    command:
      - --api=true
      - --api.dashboard=true
      - --certificatesresolvers.letsencrypt.acme.httpchallenge=true
      - --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=http
      - --certificatesresolvers.letsencrypt.acme.email=\${LETSENCRYPT_EMAIL}
      - --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json
      - --entrypoints.http.address=:80
      - --entrypoints.https.address=:443
      - --entryPoints.https.http3
      - --entryPoints.https.http3.advertisedport=443
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --providers.file.directory=/etc/traefik/dynamic
    env_file:
      - ./.env
    labels:
      - traefik.enable=true
      - traefik.http.middlewares.auth.basicauth.usersfile=/etc/traefik/.traefikpasswd
      - traefik.http.middlewares.to-https.redirectscheme.scheme=https
      - traefik.http.routers.to-https.entrypoints=http
      - traefik.http.routers.to-https.middlewares=to-https
      - traefik.http.routers.to-https.rule=HostRegexp(\`{host:.+}\`)
      - traefik.http.routers.traefik.entrypoints=https
      - traefik.http.routers.traefik.middlewares=auth
      - traefik.http.routers.traefik.rule=Host(\`\${HOST_NAME}\`)
      - traefik.http.routers.traefik.service=api@internal
      - traefik.http.routers.traefik.tls.certresolver=letsencrypt
      - traefik.http.routers.traefik.tls=true
      - traefik.http.routers.dashboard.entrypoints=https
      - traefik.http.routers.dashboard.rule=Host(\`\${DOMAIN_NAME}\`)
      - traefik.http.routers.dashboard.service=api@internal
      - traefik.http.routers.dashboard.tls.certresolver=letsencrypt
      - traefik.http.routers.dashboard.tls=true
    networks:
      - traefik
    ports:
      - 80:80
      - 443:443/tcp
      - 443:443/udp
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./acme:/letsencrypt
      - ./data:/etc/traefik/dynamic
      - ./.traefikpasswd:/etc/traefik/.traefikpasswd:ro
EOF

echo "docker-compose.yml fajl kreiran uspješno."

# Provjera postojanja Traefik mreže i kreiranje ako ne postoji
if ! docker network inspect traefik >/dev/null 2>&1; then
  echo "Kreiranje Traefik mreže..."
  docker network create traefik
  echo "Traefik mreža kreirana uspješno."
else
  echo "Traefik mreža već postoji."
fi

# Pita korisnika da li želi automatski pokrenuti Traefik
read -p "Želite li automatski pokrenuti Traefik? (da/ne): " AUTOMATIC_START
if [ "$AUTOMATIC_START" == "da" ]; then
  echo "Pokrećem Traefik..."
  cd traefik
  docker-compose up -d || docker compose up -d
  echo "Traefik je uspješno pokrenut."
else
  echo "Traefik nije automatski pokrenut. Možete ga ručno pokrenuti sa 'docker-compose up -d' ili 'docker compose up -d' u direktoriju 'traefik'."
fi
