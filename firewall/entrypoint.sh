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

iptables -A FORWARD \
    -s 172.20.0.0/24 \
    -d 172.21.0.10 \
    -p tcp \
    --dport 80 \
    -j ACCEPT

echo ""
echo "Regras carregadas!"

echo ""
echo "Tabela FORWARD:"
iptables -L FORWARD -n -v

echo ""
echo "Firewall iniciado."

tail -f /dev/null