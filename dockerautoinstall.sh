#!/bin/bash
ami=`whoami`
version=`grep -Po "(?<=^ID=).+" /etc/os-release | sed 's/"//g'`

case $version in
  ubuntu)
	if [[ "$ami" != "root" ]]; then
		echo "Please login with root account for Ubuntu"
		exit 0
	fi
    apt remove -y docker docker-ce docker-ce-cli docker-ce-rootless-extras docker-compose docker-scan-plugin docker-engine docker.io containerd runc
    apt install -y ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
	apt update && chmod a+r /etc/apt/keyrings/docker.gpg && apt update && apt install -y docker-ce docker-ce-cli docker-compose containerd.io docker-compose-plugin
    echo "vérification de la version installée:"
    docker --version
    echo "fin de l'installation"
    ;;
  debian)
	if [[ "$ami" != "root" ]]; then
		echo "Please login with root account for Debian"
		exit 0
	fi
    apt remove -y docker docker-ce docker-ce-cli docker-ce-rootless-extras docker-compose docker-scan-plugin docker-engine docker.io containerd runc
    apt update && apt install ca-certificates curl gnupg lsb-release && mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  	apt update && chmod a+r /etc/apt/keyrings/docker.gpg && apt update && apt install -y docker-ce docker-compose docker-ce-cli containerd.io docker-compose-plugin
    echo "vérification de la version installée:"
    docker --version
    echo "fin de l'installation"
    ;;
  *)
    echo "version non reconnue"
    ;;
esac
