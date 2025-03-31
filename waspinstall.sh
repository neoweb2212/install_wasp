#!/bin/bash

# Script d'installation système pour Popurank avec swap, MongoDB, Node.js, Wasp et init Git
# Auteur : Neomnia - Charles Van den driessche
# Date : 31 mars 2025

set -e

PROJECT_DIR="/var/wasp"
SWAP_FILE="$PROJECT_DIR/swapfile"
SWAP_SIZE="2G"
USER_HOME=$(eval echo ~"$USER")

echo "==> Mise à jour du système..."
sudo apt-get update -y && sudo apt-get upgrade -y

echo "==> Installation des paquets de base requis..."
sudo apt-get install -y curl gnupg util-linux ca-certificates lsb-release software-properties-common git

echo "==> Création du dossier projet $PROJECT_DIR si nécessaire..."
sudo mkdir -p "$PROJECT_DIR"
sudo chown -R "$USER:$USER" "$PROJECT_DIR"

echo "==> Configuration du fichier swap ($SWAP_SIZE)..."
if [ -f "$SWAP_FILE" ]; then
  echo "--> Ancien fichier swap trouvé. Suppression..."
  sudo swapoff "$SWAP_FILE"
  sudo rm -f "$SWAP_FILE"
fi

sudo fallocate -l "$SWAP_SIZE" "$SWAP_FILE"
sudo chmod 600 "$SWAP_FILE"
sudo mkswap "$SWAP_FILE"
sudo swapon "$SWAP_FILE"

echo "==> Vérification du swap actif :"
sudo swapon --show

echo "==> Ajout dans /etc/fstab si nécessaire..."
if ! grep -q "$SWAP_FILE" /etc/fstab; then
  echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
fi

echo "==> Installation de MongoDB 7.0..."

DISTRO="jammy"

curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor -o mongodb-server-7.0.gpg
sudo mv mongodb-server-7.0.gpg /usr/share/keyrings/
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $DISTRO/mongodb-org/7.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

sudo apt-get update -y
sudo apt-get install -y mongodb-org

echo "==> Démarrage et activation de MongoDB..."
sudo systemctl start mongod
sudo systemctl enable mongod

echo "==> Statut de MongoDB :"
sudo systemctl status mongod --no-pager

echo "==> Installation de Node.js 18 LTS..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

echo "==> Vérification de Node.js :"
node --version
npm --version

echo "==> Installation de Wasp..."
curl -sSL https://get.wasp.sh/installer.sh | sh

if ! echo "$PATH" | grep -q "$USER_HOME/.local/bin"; then
  echo "==> Ajout de ~/.local/bin au PATH..."
  echo 'export PATH="$PATH:$HOME/.local/bin"' >> "$USER_HOME/.bashrc"
  export PATH="$PATH:$HOME/.local/bin"
fi

echo "==> Vérification de Wasp :"
wasp --version || echo "⚠️ Wasp installé mais non détecté : reconnecte-toi ou recharge ton shell."

echo "==> Initialisation d’un projet Wasp dans $PROJECT_DIR..."
cd "$PROJECT_DIR"
wasp new . --template basic

echo "==> Initialisation Git..."
git init
git add .
git commit -m 'Initial commit Wasp project in /var/wasp'

echo ""
echo "✅ Environnement prêt dans /var/wasp"
echo "-> Swap actif"
echo "-> MongoDB opérationnel"
echo "-> Node.js et Wasp installés"
echo "-> Projet Wasp initialisé et prêt à être connecté à O2.dev"
