#!/bin/sh

echo "Configurando rota para a DMZ..."

ip route replace 172.21.0.0/24 via 172.20.0.2

echo "Rotas configuradas:"
ip route

exec sh