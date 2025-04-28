#!/bin/bash

# Mensagens coloridas
verde() { echo -e "\033[1;32m$1\033[0m"; }
vermelho() { echo -e "\033[1;31m$1\033[0m"; }

# Impede Ctrl+C de interromper
trap '' SIGINT

while true; do
  clear
  echo "Deseja configurar um manager ou worker?"
  echo "Digite 1 para Manager;"
  echo "Digite 2 para Worker;"
  echo "Ou qualquer outro valor para sair"
  read -p "Qual sua escolha: " escolha

  case "$escolha" in
    1)
      echo "Selecione uma das opções abaixo:"
      echo " [1] Atualizar sistema"
      echo " [2] Instalar NFS Server"
      echo " [3] Configurar NFS"
      echo " [4] Instalar Docker"
      echo " [5] Criar container MySQL"
      echo " [6] Inserir dados no banco"
      echo " [7] Iniciar Docker Swarm"
      echo " [8] Criar serviço web no cluster"
      echo " [9] Criar proxy reverso com Nginx"
      echo " [0] Voltar"

      read -p "Escolha: " servico

      case "$servico" in
        1)
          apt update -y && apt upgrade -y
          systemctl status nfs-server
          continue
        ;;
        2)
          if ! command -v exportfs &>/dev/null; then
            apt install nfs-server -y
          else
            verde "NFS Server já está instalado."
          fi
          continue
        ;;
        3)
          mkdir -p /nfs/web /nfs/db
          chmod 777 /nfs/web /nfs/db
          read -p "IP para acesso /nfs/web (* para todos): " ip1
          echo "/nfs/web $ip1(rw,sync,no_subtree_check,no_root_squash)" >>/etc/exports
          read -p "IP para acesso /nfs/db (* para todos): " ip2
          echo "/nfs/db $ip2(rw,sync,no_subtree_check,no_root_squash)" >>/etc/exports
          exportfs -ra
          systemctl restart nfs-server
          exportfs -v
          sleep 3
          continue
        ;;
        4)
          if ! command -v docker &>/dev/null; then
            apt install docker.io docker-compose -y
            verde "Docker instalado."
          else
            verde "Docker já está instalado."
          fi
          continue
        ;;
        5)
          read -s -p "Senha Root do MySQL: " senharoot
          echo "$senharoot" >/tmp/mysql_root_password
          echo

          if docker ps -a --format '{{.Names}}' | grep -q "^mysql$"; then
            verde "MySQL já existe. Pulando."
          else
            docker run -d \
              --name mysql \
              -e MYSQL_ROOT_PASSWORD="$senharoot" \
              -e MYSQL_DATABASE=banco \
              -v /nfs/db:/var/lib/mysql \
              -p 3306:3306 \
              mysql:8.0
            sleep 30
            docker exec -i mysql mysql -uroot -p"$senharoot" -e \
              "ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '$senharoot'; FLUSH PRIVILEGES;"
          fi
          continue
        ;;
        6)
          senharoot=$(cat /tmp/mysql_root_password)
          docker exec -i mysql mysql -uroot -p"$senharoot" -e \
            "USE banco; CREATE TABLE dados (
              AlunoID int,
              Nome varchar(50),
              Sobrenome varchar(50),
              Endereco varchar(150),
              Cidade varchar(50),
              Host varchar(50));"
          docker exec -i mysql mysql -uroot -p"$senharoot" -e "USE banco; SELECT * FROM dados;"
          continue
        ;;
        7)
          docker swarm init
          token=$(docker swarm join-token worker -q)
          echo "$token" >/nfs/web/token.txt
          ip_manager=$(hostname -I | awk '{print $1}')
          echo "Comando para adicionar worker:"
          echo "docker swarm join --token $token $ip_manager:2377"
          continue
        ;;
        8)
          read -p "Quantas réplicas? " replicas
          docker service create \
            --name web \
            --replicas $replicas \
            --publish 80:80 \
            --mount type=bind,source=/nfs/web,target=/app \
            webdevops/php-apache:alpine-php7
          continue
        ;;
        9)
          echo "Informe os IPs dos servidores backend:"
          read -p "IP 1: " ip1
          read -p "IP 2: " ip2
          read -p "IP 3: " ip3

          mkdir -p /proxy && chmod 777 /proxy

          cat <<EOF >/proxy/nginx.conf
http {
  upstream all {
    server $ip1:80;
    server $ip2:80;
    server $ip3:80;
  }
  server {
    listen 4500;
    location / {
      proxy_pass http://all/;
    }
  }
}
events {}
EOF

          cat <<EOF >/proxy/Dockerfile
FROM nginx
COPY nginx.conf /etc/nginx/nginx.conf
EOF

          cd /proxy
          docker build -t proxy .
          docker run --name proxy -dti -p 4500:4500 proxy
          docker ps
          verde "Proxy configurado com sucesso!"
          continue
        ;;
      esac  # <-- Fechando o case para "servico"
    ;;

    2)
      echo "Opções para worker:"
      echo " [1] Atualizar"
      echo " [2] Instalar nfs-common"
      echo " [3] Montar NFS"
      echo " [4] Instalar Docker"
      echo " [5] Entrar no cluster"

      read -p "Escolha: " servico

      case "$servico" in
        1) apt update -y && apt upgrade -y ;;
        2) apt install nfs-common -y ;;
        3)
          mkdir -p /nfs/web /nfs/db
          chmod 777 /nfs/web /nfs/db
          read -p "IP do Manager: " ip
          echo "$ip:/nfs/web /nfs/web nfs defaults,_netdev 0 0" >>/etc/fstab
          mount -a
          ;;
        4) apt install docker.io docker-compose -y ;;
        5)
          read -p "IP do Manager: " ip
          if [ -f /nfs/web/token.txt ]; then
            token=$(cat /nfs/web/token.txt)
            docker swarm join --token "$token" "$ip:2377"
          else
            vermelho "Token não encontrado."
          fi
          ;;
        *) continue ;;
      esac  # <-- Fechando o case para "servico"
      continue
    ;;
    *)
      vermelho "Saindo..."
      sleep 2
      exit
    ;;
  esac  # <-- Fechando o case para "$escolha"
done
