# FireWall-LAN-House

## situação:
Uma LAN House disponibiliza computadores para clientes utilizarem jogos online, navegarem na internet e acessarem serviços digitais. Além dos computadores utilizados pelos clientes, o estabelecimento possui servidores responsáveis pelo sistema de gerenciamento da LAN House e pelo armazenamento de seus dados.

No cenário atual, todos os dispositivos encontram-se em uma mesma rede, permitindo que computadores utilizados pelos clientes tenham acesso potencial aos servidores internos. Essa configuração representa um risco, pois um computador comprometido poderia realizar varreduras na rede e tentar acessar serviços que deveriam ser restritos.

Como solução, propõe-se a segmentação da infraestrutura em uma rede destinada aos clientes e uma DMZ destinada aos servidores. A comunicação entre essas redes será controlada por um firewall baseado em iptables, configurado com política padrão de bloqueio e liberações específicas para os serviços necessários.
