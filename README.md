# FireWall-LAN-House

## 1. Apresentação do projeto

O **FireWall-LAN-House** é um projeto de simulação de infraestrutura de redes e segurança utilizando Docker Compose, redes Docker do tipo `bridge`, um container firewall com `iptables`, um servidor web Nginx e um banco de dados PostgreSQL.

O objetivo é demonstrar como a segmentação de uma rede e a aplicação de regras de firewall podem controlar a comunicação entre diferentes ambientes, permitindo apenas os acessos necessários e bloqueando conexões não autorizadas.

O projeto foi desenvolvido para fins acadêmicos, com o propósito de demonstrar conceitos de roteamento, segmentação de redes, filtragem de pacotes, controle de acesso e validação de regras de segurança.

## 2. Definição do case

### Cenário proposto

Uma empresa fictícia de LAN House utiliza computadores para atender clientes e disponibiliza um sistema web para gerenciamento de suas operações. Esse sistema precisa acessar um banco de dados para armazenar e consultar informações.

Em uma infraestrutura sem segmentação adequada, os computadores da rede interna poderiam tentar estabelecer conexões diretamente com serviços internos, incluindo o banco de dados. Essa situação aumenta a superfície de ataque e dificulta o controle sobre quais equipamentos podem acessar cada serviço.

Para reduzir esses riscos, foi proposta uma arquitetura segmentada, na qual o computador cliente, o servidor web e o banco de dados são colocados em redes distintas, com a comunicação entre elas controlada por um container firewall.

### Serviços necessários

- **Estação cliente:** representa um computador utilizado na LAN House.
- **Firewall/roteador:** controla o encaminhamento de pacotes entre as redes.
- **Servidor web:** disponibiliza uma página HTTP por meio do Nginx.
- **Banco de dados:** utiliza PostgreSQL para representar um serviço interno que não deve ser acessado diretamente pelo cliente.

## 3. Diagnóstico: cenário atual e proposta de solução

### 3.1. Problemas identificados no cenário hipotético

Antes da implantação da solução, foram considerados os seguintes riscos:

- Ausência de segmentação entre estações de trabalho e servidores.
- Possibilidade de conexões diretas a serviços internos.
- Falta de regras explícitas para controlar o tráfego entre redes.
- Exposição desnecessária da porta do banco de dados aos computadores clientes.
- Dificuldade de verificar quais conexões são permitidas ou bloqueadas.

Esses problemas representam riscos hipotéticos utilizados para justificar a solução. O ambiente Docker foi construído para demonstrar como mitigá-los.

### 3.2. Proposta de solução

A solução utiliza três redes Docker personalizadas do tipo `bridge`, separando a rede cliente, a rede do servidor web e a rede do banco de dados.

Um container firewall possui uma interface em cada rede e atua como gateway entre elas. O encaminhamento de pacotes é habilitado e o `iptables` aplica regras de filtragem na cadeia `FORWARD`.

A política padrão da cadeia `FORWARD` é `DROP`, ou seja, os pacotes encaminhados que não correspondem às regras de permissão são descartados. São autorizadas as conexões HTTP da rede cliente para o servidor web e as conexões PostgreSQL do servidor web para o banco de dados. O tráfego de conexões já estabelecidas ou relacionadas também é permitido.

O firewall aplica regras de NAT para os fluxos previstos, facilitando o retorno das respostas pelo caminho controlado.

Essa arquitetura demonstra o princípio do menor privilégio: cada serviço recebe somente as permissões de comunicação necessárias ao cenário proposto.

## 4. Arquitetura de rede

### 4.1. Diagrama lógico

```text
                REDE CLIENTE
                10.80.1.0/24
                      |
             Cliente: 10.80.1.10
                      |
             Firewall: 10.80.1.2
                      |
              [ CONTAINER FIREWALL ]
                iptables / NAT
                      |
             Firewall: 10.80.2.2
                      |
                  REDE WEB
                10.80.2.0/24
                      |
              Nginx: 10.80.2.10
                      |
             Firewall: 10.80.3.2
                      |
                  REDE DB
                10.80.3.0/24
                      |
           PostgreSQL: 10.80.3.20
```

O diagrama representa a separação lógica das redes e os caminhos previstos de comunicação. O firewall é o gateway configurado para o encaminhamento entre elas.

### 4.2. Endereçamento IP

| Componente | Rede | Endereço IP |
|---|---|---|
| Cliente | `cliente_net` | `10.80.1.10` |
| Firewall — interface cliente | `cliente_net` | `10.80.1.2` |
| Firewall — interface web | `web_net` | `10.80.2.2` |
| Servidor web Nginx | `web_net` | `10.80.2.10` |
| Firewall — interface banco | `db_net` | `10.80.3.2` |
| Banco PostgreSQL | `db_net` | `10.80.3.20` |

### 4.3. Redes Docker

| Rede | Sub-rede | Finalidade |
|---|---|---|
| `cliente_net` | `10.80.1.0/24` | Comunicação da estação cliente com o firewall. |
| `web_net` | `10.80.2.0/24` | Comunicação do servidor web com o firewall. |
| `db_net` | `10.80.3.0/24` | Comunicação do banco de dados com o firewall. |

As redes são definidas explicitamente no `docker-compose.yml`, utilizando o driver `bridge` e sub-redes personalizadas.

O cliente está conectado somente à rede cliente, o Nginx somente à rede web e o PostgreSQL somente à rede do banco. O firewall possui interfaces nas três redes para realizar o roteamento e aplicar as regras de filtragem.

## 5. Matriz de regras de segurança

A tabela apresenta as regras configuradas e o comportamento esperado do ambiente.

| Origem | Destino | Porta/protocolo | Ação | Justificativa |
|---|---|---|---|---|
| Qualquer origem encaminhada | Qualquer destino encaminhado | Todos | DROP por padrão | Bloquear tráfego entre redes sem autorização explícita. |
| Conexões estabelecidas ou relacionadas | Destino correspondente | Conforme a conexão | ACCEPT | Permitir o retorno do tráfego de conexões autorizadas. |
| Rede Cliente (`10.80.1.0/24`) | Servidor Web (`10.80.2.10`) | TCP 80 | ACCEPT | Permitir que o cliente utilize o sistema web. |
| Servidor Web (`10.80.2.10`) | Banco (`10.80.3.20`) | TCP 5432 | ACCEPT | Permitir que a aplicação web acesse o PostgreSQL. |
| Rede Cliente (`10.80.1.0/24`) | Banco (`10.80.3.20`) | TCP 5432 | DROP pela política padrão | Impedir o acesso direto do cliente ao banco de dados. |
| Rede Cliente | Servidor Web | TCP 443 | Sem liberação configurada | HTTPS não faz parte da implementação atual. |

### Observações sobre as regras

A regra que impede o acesso direto do cliente ao PostgreSQL não é uma regra `DROP` específica por endereço e porta: o bloqueio ocorre porque a cadeia `FORWARD` utiliza a política padrão `DROP` e não existe uma regra de permissão para esse fluxo.

O firewall também utiliza regras de NAT na cadeia `POSTROUTING` para os fluxos previstos entre as redes cliente/web e web/banco.

Na implementação atual, as políticas `INPUT` e `OUTPUT` estão configuradas como `ACCEPT`. A política padrão `DROP` está aplicada à cadeia `FORWARD`, responsável por filtrar os pacotes encaminhados entre as redes.

## 6. Tecnologias utilizadas

- **Docker:** execução dos componentes em containers isolados.
- **Docker Compose:** definição dos serviços, redes, endereços IP, volumes e dependências.
- **Alpine Linux:** imagem base dos containers cliente e firewall.
- **iptables:** configuração das regras de filtragem e NAT.
- **Nginx:** servidor web HTTP.
- **PostgreSQL 16:** banco de dados utilizado para simular um serviço interno.
- **Shell Script (`entrypoint.sh`):** configuração automática das rotas e das regras na inicialização dos containers.
- **Git e GitHub:** versionamento e compartilhamento do projeto.

## 7. Estrutura do projeto

A estrutura principal dos arquivos é organizada da seguinte maneira:

```text
FireWall-LAN-House/
├── docker-compose.yml
├── cliente/
│   ├── Dockerfile
│   └── entrypoint.sh
├── firewall/
│   ├── Dockerfile
│   └── entrypoint.sh
├── web/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── index.html
└── README.md
```

### Responsabilidade dos arquivos

- `docker-compose.yml`: define os containers, as redes, os endereços IP, as permissões e o volume do servidor web.
- `cliente/Dockerfile`: prepara a imagem da estação cliente.
- `cliente/entrypoint.sh`: configura as rotas do cliente para as redes internas por meio do firewall.
- `firewall/Dockerfile`: prepara a imagem do firewall e instala as ferramentas necessárias.
- `firewall/entrypoint.sh`: habilita o roteamento, limpa regras antigas e carrega as regras de filtragem e NAT automaticamente.
- `web/Dockerfile`: prepara a imagem do Nginx e instala as ferramentas necessárias para configurar a rota e testar o PostgreSQL.
- `web/entrypoint.sh`: configura a rota para a rede do banco e inicia o servidor web.
- `web/index.html`: contém a página HTML utilizada para validar o funcionamento do servidor.
- `README.md`: documenta o cenário, a arquitetura, as regras e os testes.

## 8. Como executar o projeto

### 8.1. Pré-requisitos

- Docker instalado e em execução.
- Docker Compose disponível por meio do comando `docker compose`.
- Terminal compatível com os comandos apresentados, como PowerShell no Windows.

### 8.2. Iniciar o ambiente

No terminal, acesse a pasta raiz do repositório e execute:

```powershell
docker compose up -d --build
```

O comando constrói as imagens necessárias e inicia os containers em segundo plano. Durante a inicialização, os scripts de entrada configuram as rotas e as regras de firewall.

### 8.3. Verificar os containers

```powershell
docker compose ps -a
```

Os quatro serviços esperados são:

- `lanhouse-cliente`
- `lanhouse-firewall`
- `lanhouse-web`
- `lanhouse-db`

Todos devem estar em execução para a realização dos testes.

### 8.4. Consultar os logs

```powershell
docker compose logs --tail=50 cliente firewall web
```

Para consultar somente os logs do firewall:

```powershell
docker compose logs firewall
```

### 8.5. Encerrar o ambiente

```powershell
docker compose down
```

Esse comando encerra e remove os containers e a rede criada pelo Compose. A imagem e os arquivos locais do projeto permanecem disponíveis. Como o ambiente utiliza a configuração atual sem volume persistente declarado para os dados do PostgreSQL, não se deve considerar os dados do banco preservados após a remoção e recriação do container.

## 9. Metodologia de testes e validação

Os testes devem verificar tanto as conexões permitidas quanto as conexões que precisam ser bloqueadas.

Os comandos a seguir foram utilizados no ambiente e podem ser repetidos pelo avaliador.

### Teste 1 — Verificar a política e as regras do firewall

**Objetivo:** confirmar que o encaminhamento utiliza política padrão `DROP` e possui as permissões previstas.

```powershell
docker exec lanhouse-firewall iptables -L FORWARD -n -v
```

**Resultado esperado:** a saída apresenta `Chain FORWARD (policy DROP)` e regras para conexões estabelecidas, HTTP para o servidor web e PostgreSQL do servidor web para o banco.

Os contadores de pacotes e bytes permitem observar a atividade das regras.

### Teste 2 — Acesso HTTP do cliente ao servidor web

**Objetivo:** confirmar que o cliente consegue acessar o serviço web autorizado.

```powershell
docker exec lanhouse-cliente wget -qO- http://10.80.2.10
```

**Resultado esperado:** o terminal apresenta o conteúdo HTML da página inicial, incluindo a mensagem de que o servidor web está funcionando corretamente.

**Resultado observado:** o conteúdo HTML foi recebido com sucesso.

### Teste 3 — Disponibilidade do PostgreSQL a partir do servidor web

**Objetivo:** verificar se o serviço PostgreSQL está acessível pelo caminho autorizado entre a rede web e a rede do banco.

```powershell
docker exec lanhouse-web pg_isready -h 10.80.3.20 -p 5432 -U lanhouse
```

**Resultado esperado:**

```text
10.80.3.20:5432 - accepting connections
```

Esse resultado confirma que o PostgreSQL está aceitando conexões. O comando não realiza, por si só, uma consulta SQL nem comprova autenticação com o banco.

**Resultado observado:** o PostgreSQL respondeu que estava aceitando conexões.

### Teste 4 — Bloqueio do acesso direto do cliente ao banco

**Objetivo:** confirmar que a estação cliente não consegue estabelecer uma conexão TCP diretamente com a porta PostgreSQL.

Primeiro, instale a ferramenta de teste no container cliente:

```powershell
docker exec lanhouse-cliente apk add --no-cache netcat-openbsd
```

Depois, execute:

```powershell
docker exec lanhouse-cliente sh -c 'nc -z -w 3 10.80.3.20 5432; echo Codigo de retorno: $?'
```

**Resultado esperado:** código de retorno `1`, indicando que a conexão não foi estabelecida.

**Resultado observado:** o comando retornou código `1`, confirmando que a tentativa de conexão não foi estabelecida.

### Teste 5 — Verificar os pacotes descartados

**Objetivo:** observar os contadores do firewall após as tentativas de conexão.

```powershell
docker exec lanhouse-firewall iptables -L FORWARD -n -v
```

**Resultado observado:** após a tentativa de acesso direto ao banco, a política `DROP` apresentava nove pacotes e 540 bytes descartados. Os contadores são cumulativos e podem incluir outros pacotes descartados, portanto não identificam individualmente a origem de cada descarte.

### Resumo da validação

| Teste | Resultado observado | Situação |
|---|---|---|
| Containers em execução | Os quatro containers estavam `Up` | Aprovado |
| Política `FORWARD` | Política padrão `DROP` | Aprovado |
| Cliente acessando o Nginx | Página HTML recebida | Aprovado |
| Servidor web verificando o PostgreSQL | Serviço aceitando conexões | Aprovado |
| Cliente tentando acessar diretamente o PostgreSQL | Código de retorno `1` | Aprovado |
| Contadores do firewall | Pacotes descartados registrados | Aprovado |

Os testes demonstram que o serviço web está acessível, que o PostgreSQL responde a partir do servidor web e que a tentativa de conexão direta do cliente ao banco não foi estabelecida.

## 10. Limitações e possíveis melhorias

O ambiente foi construído para demonstrar os princípios básicos de segmentação e filtragem de redes. Algumas melhorias possíveis para uma versão futura são:

- Aplicar políticas mais restritivas também às cadeias `INPUT` e `OUTPUT`, com regras explícitas para o tráfego necessário ao funcionamento do firewall.
- Adicionar HTTPS com certificado e configuração do servidor web.
- Implementar uma aplicação web que execute consultas reais ao PostgreSQL, validando a comunicação em nível de aplicação.
- Adicionar regras de registro de pacotes bloqueados para facilitar a auditoria.
- Automatizar os testes positivos e negativos para facilitar a repetição da validação.
- Avaliar a persistência dos dados do PostgreSQL por meio de um volume, caso seja necessária em uma evolução do projeto.

## 11. Conclusão

O projeto FireWall-LAN-House demonstra uma arquitetura de rede segmentada com containers Docker, na qual um firewall atua como gateway e controla o tráfego encaminhado entre a estação cliente, o servidor web e o banco de dados.

A utilização de redes `bridge` separadas, rotas explícitas, regras de `iptables` e scripts de inicialização permite demonstrar o acesso autorizado ao servidor web, a comunicação do servidor web com o PostgreSQL e o bloqueio de uma tentativa de acesso direto do cliente ao banco.

Os resultados obtidos nos testes fornecem evidências práticas do funcionamento da arquitetura implementada e da aplicação das regras de segurança propostas para o cenário hipotético de uma LAN House.
