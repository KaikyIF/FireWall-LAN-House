#!/bin/sh

echo "================================="
echo " Iniciando Firewall da LAN House"
echo "================================="

echo "Interfaces:"
ip addr

echo ""
echo "Habilitando roteamento..."
sysctl -w net.ipv4.ip_forward=1

echo ""
echo "Limpando regras antigas..."
iptables -F
iptables -X

echo ""
echo "Configurando politicas padrão..."

iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

echo ""
echo "Liberando trafego estabelecido..."

iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo ""
echo "Liberando Cliente -> Web HTTP..."

echo "Configurando NAT para o acesso a DMZ..."
iptables -t nat -A POSTROUTING \
    -s 172.20.0.0/24 \
    -d 172.21.0.0/24 \
    -j MASQUERADE

iptables -A FORWARD \
    -s 172.20.0.0/24 \
    -d 172.21.0.10 \
    -p tcp \
    --dport 80 \
    -j ACCEPT

echo ""
echo "Liberando Web -> Banco de dados PostgreSQL..."

iptables -A FORWARD \
    -s 172.21.0.10 \
    -d 172.21.0.20 \
    -p tcp \
    --dport 5432 \
    -j ACCEPT

echo ""
echo "Regras carregadas!"

echo ""
echo "Tabela FORWARD:"
iptables -L FORWARD -n -v

echo ""
echo "Firewall iniciado."

tail -f /dev/null