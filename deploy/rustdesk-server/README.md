# Servidor RustDesk próprio (VPS)

Sobe o `hbbs` (servidor de ID) e o `hbbr` (relay) com Docker.

## Requisitos

- VPS Ubuntu 22.04+/Debian 12+, com 1 vCPU e 1 GB de RAM (já é suficiente)
- Acesso root via SSH
- Portas liberadas no firewall da VPS **e no painel do provedor** (Security Group etc.):

| Porta | Protocolo | Uso |
|---|---|---|
| 21115 | TCP | hbbs: teste de NAT |
| 21116 | TCP + UDP | hbbs: registro de ID e hole punching |
| 21117 | TCP | hbbr: relay |
| 21118 | TCP | hbbs: cliente web (opcional) |
| 21119 | TCP | hbbr: cliente web (opcional) |

## Instalação com Dokploy (recomendado)

1. No Dokploy, crie um **Project** (por exemplo, `rustdesk`) e, dentro dele, **Create Service → Compose**.
2. Em **Compose Type**, escolha **Docker Compose**, não *Stack*: o modo Swarm não aceita `network_mode: host`.
3. Em **Provider**, escolha **Raw** e cole o conteúdo de [`docker-compose.dokploy.yml`](docker-compose.dokploy.yml).
4. Deixe **Isolated Deployment** desligado e não adicione **Domains**. O RustDesk usa TCP/UDP puro e não passa pelo Traefik.
5. Clique em **Deploy**.
6. Abra **Logs** do serviço `hbbs` e procure a linha `Key: ...`. Essa é a chave dos clientes.
   Pelo SSH também dá para ver:
   ```bash
   cat /etc/dokploy/compose/*/files/rustdesk-data/id_ed25519.pub
   ```

Os dados ficam em `../files/rustdesk-data`, que o Dokploy mantém entre um deploy e outro. Não use `./data`: o Dokploy apaga essa pasta a cada deploy, e a chave mudaria.

Libere as portas da tabela acima no UFW da VPS e no painel do provedor:

```bash
ufw allow 21115:21119/tcp && ufw allow 21116/udp
```

Se for usar domínio, crie um registro DNS **A** (por exemplo, `rustdesk.seudominio.com`) apontando para o IP da VPS, com o **proxy desligado** se usar Cloudflare (nuvem cinza).

## Página de download (Dokploy)

[`docker-compose.download.yml`](docker-compose.download.yml) publica em `https://acesso.rafaelmarcolino.online` uma página com o botão de download.
O executável oficial do RustDesk é baixado do GitHub na primeira execução e entregue já com o nome `RafaDesk-licensed-<config>.exe`.
É esse nome que faz o app conectar no seu servidor, então o `-licensed-<config>` precisa continuar no arquivo.

- Serviço no Dokploy: `rustdesk-download`, Domain `acesso.rafaelmarcolino.online`, service `web`, porta 80, HTTPS com Let's Encrypt.
- **Depois de editar a página ou o nginx (blocos `configs:`), clique em Stop e depois em Deploy.** Se clicar só em Deploy, o container `web` não é recriado e continua com a versão antiga.
- Para trocar a versão do RustDesk, substitua `1.5.1` em todas as ocorrências do arquivo.

## Instalação manual (sem Dokploy)

No seu PC (PowerShell ou Git Bash), envie a pasta para a VPS:

```bash
scp -r deploy/rustdesk-server root@IP_DA_VPS:/opt/
```

Na VPS:

```bash
ssh root@IP_DA_VPS
cd /opt/rustdesk-server
chmod +x setup.sh
./setup.sh
```

No final, o script mostra o **IP** e a **chave**. Guarde os dois.

## Configurar os clientes

Em cada RustDesk (cliente oficial), vá em **Configurações → Rede → Servidor de ID/Relay**:

- **Servidor de ID:** `IP_DA_VPS` (ou seu domínio)
- **Servidor relay:** `IP_DA_VPS`
- **Servidor de API:** deixe vazio
- **Chave:** o conteúdo de `data/id_ed25519.pub`

As duas máquinas, a que acessa e a acessada, precisam estar com a mesma configuração.

## Operação

```bash
cd /opt/rustdesk-server
docker compose ps              # status
docker compose logs -f hbbs    # logs
docker compose pull && docker compose up -d   # atualizar
docker compose down            # parar
```

## Backup

A pasta `data/` guarda a chave privada (`id_ed25519`) e o banco de IDs. Faça backup dela.
Se a chave mudar, você vai precisar reconfigurar todos os clientes.

```bash
tar czf rustdesk-data-$(date +%F).tgz -C /opt/rustdesk-server data
```

## Problemas comuns

- **"Pronto" não aparece / fica "Conectando à rede"**: a porta 21116 (TCP **e** UDP) está bloqueada, ou o servidor de ID está errado.
- **"Key mismatch"**: a chave no cliente está diferente da que está em `data/id_ed25519.pub`.
- **Conexão lenta ou falhando**: o relay (21117) está bloqueado no firewall do provedor.
