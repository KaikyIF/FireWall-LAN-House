
#!/bin/sh

echo "================================="
echo " Iniciando Firewall da LAN House"
echo "================================="

echo "Habilitando roteamento..."
sysctl -w net.ipv4.ip_forward=1

echo "Limpando regras antigas..."
iptables -F
iptables -X
iptables -t nat -F

echo "Configurando politicas padrao..."
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

echo "Liberando conexoes estabelecidas..."
iptables -A FORWARD \
    -m conntrack \
    --ctstate ESTABLISHED,RELATED \
    -j ACCEPT

echo "Liberando Cliente -> Web HTTP..."
iptables -A FORWARD \
    -s 10.80.1.0/24 \
    -d 10.80.2.10 \
    -p tcp \
    --dport 80 \
    -j ACCEPT

echo "Liberando Web -> Banco PostgreSQL..."
iptables -A FORWARD \
    -s 10.80.2.10 \
    -d 10.80.3.20 \
    -p tcp \
    --dport 5432 \
    -j ACCEPT

echo "Configurando NAT para o retorno pelo firewall..."
iptables -t nat -A POSTROUTING \
    -s 10.80.1.0/24 \
    -d 10.80.2.0/24 \
    -j MASQUERADE

iptables -t nat -A POSTROUTING \
    -s 10.80.2.0/24 \
    -d 10.80.3.0/24 \
    -j MASQUERADE

echo "Regras carregadas!"
echo ""
echo "Tabela FORWARD:"
iptables -L FORWARD -n -v

echo ""
echo "Tabela NAT:"
iptables -t nat -L POSTROUTING -n -v

echo ""
echo "Firewall iniciado."

tail -f /dev/null
