#!/bin/bash

set -e

# Variables
AMI=$(whoami)
DISTRO=$(grep -Po '(?<=^ID=).+' /etc/os-release | tr -d '"')
VERSION_ID=$(grep -Po '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
CODENAME=$(grep -Po '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '"')

# Vérification root
if [[ "$AMI" != "root" ]]; then
    echo "Ce script doit être exécuté en tant que root"
    exit 1
fi

# Fonction de nettoyage commune
cleanup_docker() {
    echo "==> Suppression des anciennes versions Docker..."
    apt-get remove -y docker docker-engine docker.io containerd runc \
        docker-ce docker-ce-cli docker-ce-rootless-extras \
        docker-compose docker-compose-plugin docker-scan-plugin \
        docker-buildx-plugin 2>/dev/null || true
    apt-get autoremove -y
}

# Installation pour Debian 13 (trixie) et supérieur
install_docker_debian13plus() {
    echo "==> Installation Docker pour Debian ${VERSION_ID} (${CODENAME})"
    
    cleanup_docker
    
    # Installation des prérequis
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    
    # Configuration du dépôt Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    
    # Gestion spécifique pour Debian 13+ (testing/unstable)
    # On utilise le dépôt bookworm (stable) car trixie n'est pas encore officiellement supporté
    DOCKER_CODENAME="bookworm"
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/debian ${DOCKER_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
}

# Installation pour Debian 12 (bookworm)
install_docker_debian12() {
    echo "==> Installation Docker pour Debian ${VERSION_ID} (${CODENAME})"
    
    cleanup_docker
    
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/debian ${CODENAME} stable" > /etc/apt/sources.list.d/docker.list
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
}

# Installation pour Ubuntu
install_docker_ubuntu() {
    echo "==> Installation Docker pour Ubuntu ${VERSION_ID} (${CODENAME})"
    
    cleanup_docker
    
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu ${CODENAME} stable" > /etc/apt/sources.list.d/docker.list
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
}

# Configuration post-installation
post_install() {
    echo "==> Configuration post-installation..."
    
    # Activation et démarrage de Docker
    systemctl enable docker
    systemctl start docker
    
    # Test d'installation
    echo ""
    echo "==> Vérification de l'installation :"
    docker --version
    docker compose version
    
    # Test fonctionnel
    echo ""
    echo "==> Test de fonctionnement :"
    if docker run --rm hello-world >/dev/null 2>&1; then
        echo "✓ Docker fonctionne correctement"
    else
        echo "✗ Erreur lors du test Docker"
        exit 1
    fi
    
    echo ""
    echo "==> Installation terminée avec succès"
    echo ""
    echo "Notes importantes :"
    echo "  - Docker Compose v2 est installé comme plugin : utilisez 'docker compose' (sans tiret)"
    echo "  - Pour ajouter un utilisateur au groupe docker : usermod -aG docker USERNAME"
    echo "  - Déconnexion/reconnexion nécessaire pour appliquer les permissions de groupe"
}

# Logique principale
case $DISTRO in
    debian)
        VERSION_MAJOR=$(echo "$VERSION_ID" | cut -d. -f1)
        
        if [[ $VERSION_MAJOR -ge 13 ]]; then
            install_docker_debian13plus
        elif [[ $VERSION_MAJOR -eq 12 ]]; then
            install_docker_debian12
        else
            echo "Debian $VERSION_ID n'est pas supporté par ce script (minimum : Debian 12)"
            exit 1
        fi
        ;;
    ubuntu)
        install_docker_ubuntu
        ;;
    *)
        echo "Distribution non supportée : $DISTRO"
        echo "Ce script supporte uniquement Debian 12+ et Ubuntu"
        exit 1
        ;;
esac

post_install
