# Samba Hardening e Alertas em Tempo Real no Discord

Este documento descreve um laboratório doméstico (*homelab*) de segurança para identificar e corrigir compartilhamentos SMB acessíveis sem autenticação e configurar notificações no Discord quando um cliente acessar um compartilhamento monitorado.

> Use as técnicas de reconhecimento somente em sistemas e redes que você administra ou tem autorização para testar.

## Sumário

1. [Contexto e risco](#contexto-e-risco)
2. [Reconhecimento com Nmap e smbclient](#reconhecimento-com-nmap-e-smbclient)
3. [Hardening do Samba](#hardening-do-samba)
4. [Alertas no Discord](#alertas-no-discord)
5. [Validação](#validação)

## Contexto e risco

Durante a análise de um ambiente de laboratório com CasaOS sobre Ubuntu Server, foi identificada uma possível exposição de dados por compartilhamentos SMB permissivos. Uma configuração inadequada pode permitir que clientes da rede local leiam ou alterem arquivos sem autenticação.

## Reconhecimento com Nmap e smbclient

Use o Nmap para verificar as portas relevantes no servidor:

```bash
nmap -p 80,445 192.168.15.150
```

Verifique se os compartilhamentos podem ser enumerados anonimamente:

```bash
smbclient -L //192.168.15.150 -N
```

O parâmetro `-N` tenta a conexão sem solicitar senha. Se o comando listar compartilhamentos que deveriam exigir autenticação, revise as permissões e as opções de convidado do Samba.

## Hardening do Samba

Revise os arquivos de configuração utilizados pelo servidor, por exemplo `/etc/samba/smb.conf` e, se estiver incluído, `/etc/samba/smb.casa.conf`. Faça uma cópia de segurança antes de alterar a configuração.

Na seção `[global]`, desative o mapeamento de conexões não autenticadas para convidados:

```ini
[global]
	map to guest = Never
```

Para cada compartilhamento que deve ser privado, use uma configuração equivalente a esta, adaptando os caminhos e o grupo de acesso ao seu ambiente:

```ini
[Media]
	path = /caminho/do/compartilhamento
	browseable = no
	guest ok = no
	valid users = labuser
	read only = no
	create mask = 0660
	directory mask = 0770
```

`valid users` limita o acesso aos usuários listados. `browseable = no` oculta o compartilhamento da listagem, mas não substitui autenticação nem controle de permissões. Remova opções como `force user = root` e evite permissões amplas como `0777`.

Confirme a configuração e reinicie o serviço:

```bash
testparm
sudo systemctl restart smbd
```

## Alertas no Discord

O script de notificação deste repositório está em [`samba-alert.sh`](samba-alert.sh). Instale-o no caminho usado pela configuração do Samba e restrinja a escrita do arquivo ao administrador:

```bash
sudo install -o root -g root -m 0750 samba-alert.sh /usr/local/bin/samba-alert.sh
```

No script, substitua `SUA_URL_DO_WEBHOOK_DO_DISCORD_AQUI` pela URL do webhook. Trate essa URL como uma senha: não a publique no repositório nem em capturas de tela. O script registra chamadas em `/tmp/samba-debug.log` e respostas/erros do `curl` em `/tmp/samba-curl-error.log`.

Adicione a chamada à seção de cada compartilhamento que deseja monitorar, no arquivo efetivamente carregado pelo Samba:

```ini
root preexec = /usr/local/bin/samba-alert.sh %U %I %S
```

Os parâmetros `%U`, `%I` e `%S` são, respectivamente, o usuário, o endereço IP do cliente e o nome do compartilhamento. `root preexec` executa o comando com privilégios de root antes de estabelecer a conexão ao compartilhamento; mantenha o script sob propriedade de root e não permita que usuários comuns o modifiquem.

O script consulta a tabela de vizinhos do sistema para tentar obter o endereço MAC. Esse dado pode aparecer como desconhecido quando não há uma entrada válida na tabela ou quando o cliente está em outra rede, separado por roteador.

Depois de editar a configuração, valide-a e reinicie o serviço:

```bash
testparm
sudo systemctl restart smbd
```

## Validação

1. Tente enumerar os compartilhamentos sem credenciais. O acesso anônimo não deve revelar os compartilhamentos privados:

   ```bash
   smbclient -L //192.168.15.150 -N
   ```

2. Acesse o compartilhamento com uma conta autorizada, por exemplo `labuser`.
3. Confirme o recebimento do alerta no canal do Discord.
4. Se não houver alerta, verifique os logs locais e confirme que o Samba está carregando o arquivo editado.
