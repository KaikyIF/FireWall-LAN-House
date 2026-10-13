
# FireWall-LAN-House

## 1. Definição do Case

O projeto simula a infraestrutura de rede de uma LAN House utilizando Docker e Docker Compose. O objetivo é demonstrar a segmentação de redes, o controle de tráfego entre diferentes segmentos e a aplicação de regras de segurança por meio de um firewall Linux com iptables.

A infraestrutura possui três redes isoladas: a rede dos clientes, a rede do servidor web e a rede do banco de dados. O firewall funciona como roteador entre esses segmentos e controla quais conexões podem atravessar as redes.

## 2. Diagnóstico do cenário

Em uma LAN House, os computadores dos clientes não devem ter acesso irrestrito aos servidores e aos serviços internos. A ausência de segmentação e de regras de filtragem pode permitir acessos indevidos a serviços que deveriam ser restritos.

Para reduzir esse risco, o projeto utiliza:
- Segmentação da rede em sub-redes distintas.
- Firewall com política padrão de bloqueio do tráfego encaminhado.
- Liberação explícita dos serviços necessários.
- Isolamento do banco de dados em uma rede própria.
- Registro de contadores de pacotes para auxiliar na análise das regras.

## 3. Tecnologias utilizadas

- Docker: execução dos componentes em containers.
- Docker Compose: definição e gerenciamento da infraestrutura.
- Alpine Linux: base dos containers de cliente e firewall.
- iptables: filtragem de pacotes e configuração de NAT.
- Nginx: servidor HTTP.
- PostgreSQL: banco de dados.
- curl e Nmap: testes de conectividade e diagnóstico.

## 4. Arquitetura da rede

A infraestrutura é composta pelos seguintes elementos:

| Componente | Endereço IP | Rede | Função |
|---|---|---|---|
| Cliente | 172.20.0.10 | cliente_net | Simula o computador de um usuário |
| Firewall - interface cliente | 172.20.0.2 | cliente_net | Gateway da rede cliente |
| Firewall - interface web | 172.21.0.2 | web_net | Gateway da rede web |
| Servidor web | 172.21.0.10 | web_net | Disponibiliza o serviço HTTP |
| Firewall - interface banco | 172.22.0.2 | db_net | Gateway da rede do banco |
| Banco de dados | 172.22.0.20 | db_net | Disponibiliza o PostgreSQL |

### Redes

- `cliente_net`: 172.20.0.0/24
- `web_net`: 172.21.0.0/24
- `db_net`: 172.22.0.0/24

O firewall possui uma interface em cada rede. O cliente e o servidor web possuem rotas explícitas para alcançar as redes remotas através do firewall.

O banco de dados permanece em uma rede separada, sem conexão direta à rede dos clientes ou à rede web. Dessa forma, o tráfego entre esses segmentos precisa passar pelas regras de encaminhamento do firewall.

## 5. Matriz de regras

| Origem | Destino | Serviço | Decisão |
|---|---|---|---|
| Cliente | Servidor web | TCP/80 (HTTP) | Permitir |
| Servidor web | Banco de dados | TCP/5432 (PostgreSQL) | Permitir |
| Conexões autorizadas | Retorno da conexão | ESTABLISHED, RELATED | Permitir |
| Cliente | Banco de dados | TCP/5432 | Bloquear |
| Cliente | Servidor web | Portas diferentes da 80 | Bloquear |
| Outras conexões encaminhadas | Qualquer rede | Não autorizadas | Bloquear |

A cadeia `FORWARD` utiliza a política padrão `DROP`. Assim, o tráfego encaminhado só é permitido quando corresponde a uma regra explícita.

A cadeia `INPUT` também utiliza `DROP`, permitindo loopback e tráfego de retorno estabelecido destinado ao próprio firewall. A cadeia `OUTPUT` utiliza `ACCEPT` para permitir o tráfego originado pelo firewall.

O NAT é utilizado para que as respostas das conexões autorizadas retornem pelo firewall.

## 6. Como executar

### Pré-requisitos

- Docker instalado e em execução.
- Docker Compose disponível pelo comando `docker compose`.
- Terminal aberto na pasta do projeto.

### Inicializar a infraestrutura

Na raiz do projeto, execute:

```bash
docker compose down
docker compose up -d --build
```

O primeiro comando encerra e remove os containers e as redes gerenciadas pelo Compose anterior. O segundo constrói as imagens e inicia os serviços.

Para verificar o estado dos containers:

```bash
docker compose ps
```

Para consultar os logs:

```bash
docker compose logs
```

Para consultar somente os logs do firewall:

```bash
docker compose logs firewall
```

## 7. Metodologia de testes

Os testes abaixo devem ser executados após a inicialização dos containers.

### Teste 1 — Verificar o serviço HTTP permitido

Execute:

```bash
docker exec lanhouse-cliente curl -m 5 http://172.21.0.10
```

Resultado esperado: o comando retorna o HTML da página da LAN House. Isso demonstra que o cliente consegue acessar o servidor web pela porta 80 através do firewall.

### Teste 2 — Verificar o bloqueio do acesso ao banco pelo cliente

Execute:

```bash
docker exec lanhouse-cliente nmap -Pn -p 5432 -T3 172.22.0.20
```

Resultado esperado: a porta 5432 aparece como `filtered` ou sem resposta, indicando que o tráfego do cliente está sendo filtrado.

### Teste 3 — Verificar o acesso ao PostgreSQL a partir do servidor web

Execute:

```bash
docker exec lanhouse-web pg_isready -h 172.22.0.20 -p 5432 -U lanhouse -t 5
```

Resultado esperado: uma mensagem informando que o servidor aceita conexões. Isso demonstra que o servidor web consegue alcançar o PostgreSQL pela rota configurada através do firewall.

Esse teste verifica a disponibilidade de conexão do PostgreSQL; não substitui um teste de autenticação nem uma consulta SQL.

### Teste 4 — Consultar as regras do firewall

Execute:

```bash
docker exec lanhouse-firewall iptables -L FORWARD -n -v
```

Resultado esperado:
- Política padrão `DROP`.
- Regra para cliente acessar o servidor web na porta 80.
- Regra para o servidor web acessar o banco na porta 5432.
- Regra para conexões estabelecidas e relacionadas.

Os contadores de pacotes e bytes permitem observar se as regras estão sendo utilizadas durante os testes.

### Teste 5 — Consultar as regras de NAT

Execute:

```bash
docker exec lanhouse-firewall iptables -t nat -L POSTROUTING -n -v
```

Resultado esperado: exibição das regras `MASQUERADE` configuradas para os fluxos autorizados entre as redes.

### Teste 6 — Verificar as rotas do cliente

Execute:

```bash
docker exec lanhouse-cliente ip route
```

Resultado esperado: presença de rotas para `172.21.0.0/24` e `172.22.0.0/24` usando o gateway `172.20.0.2`.

## 8. Estrutura dos arquivos

```text
FireWall-LAN-House/
├── compose.yaml
├── README.md
├── cliente/
│   ├── Dockerfile
│   └── entrypoint.sh
├── firewall/
│   ├── Dockerfile
│   └── entrypoint.sh
└── web/
    ├── Dockerfile
    ├── entrypoint.sh
    └── index.html
```

- `compose.yaml`: define os serviços, endereços IP e redes.
- `cliente/Dockerfile`: constrói a imagem do cliente com ferramentas de diagnóstico.
- `cliente/entrypoint.sh`: configura as rotas do cliente.
- `firewall/Dockerfile`: instala as ferramentas necessárias ao firewall.
- `firewall/entrypoint.sh`: ativa o roteamento e carrega as regras de filtragem e NAT.
- `web/Dockerfile`: constrói a imagem do Nginx com ferramentas de teste.
- `web/entrypoint.sh`: configura a rota para a rede do banco e inicia o Nginx.
- `web/index.html`: página disponibilizada pelo servidor HTTP.

## 9. Considerações finais

O projeto demonstra como a segmentação de redes e o uso de regras de firewall podem restringir o acesso aos serviços de uma infraestrutura simulada.

O cliente possui acesso HTTP ao servidor web, enquanto o acesso ao PostgreSQL é autorizado somente para o servidor web. A política padrão de bloqueio reduz a possibilidade de conexões não previstas, e os testes permitem observar o comportamento das regras.

A solução tem finalidade didática. Em um ambiente de produção, seria necessário complementar a configuração com gestão segura de credenciais, persistência adequada do banco, monitoramento, políticas de atualização e revisão das permissões dos containers.
