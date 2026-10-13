
#!/bin/sh

echo "Configurando rotas para as redes internas..."

ip route replace 10.80.2.0/24 via 10.80.1.2
ip route replace 10.80.3.0/24 via 10.80.1.2

echo "Rotas configuradas:"
ip route

echo "Cliente iniciado."
exec sh
