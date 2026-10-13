
#!/bin/sh

echo "Configurando rota para o banco de dados..."

ip route replace 10.80.3.0/24 via 10.80.2.2

echo "Rotas configuradas:"
ip route

echo "Iniciando servidor web..."
exec "$@"
