# Configuração de Ambiente e Acesso Seguro via SSH

## Aviso importante

Este documento utiliza placeholders estruturados com sinais de menor e maior, como `<USUARIO>`, `<IP_DO_SERVIDOR>` e `<SEU_EMAIL_OU_COMENTARIO>`. Substitua esses valores pelos dados da sua infraestrutura antes de executar os comandos. Nunca compartilhe, commite ou exponha senhas, chaves privadas, tokens ou endereços reais neste arquivo.

## Objetivo

Documentar um procedimento padronizado de instalação, configuração e proteção de um servidor Linux para acesso remoto via SSH (Secure Shell), substituindo a autenticação por senha tradicional pela autenticação baseada em chaves criptográficas assimétricas utilizando o algoritmo Ed25519.

## Pré-requisitos

Antes de iniciar, certifique-se de ter:

- Sistema operacional Linux baseado em Debian/Ubuntu (o procedimento também pode ser adaptado para distribuições equivalentes com gerenciador de pacotes semelhante).
- Permissões de administrador, como usuário root ou um usuário com privilégios sudo.
- Acesso prévio ao terminal do servidor, seja por console, máquina virtual ou uma conexão SSH inicial com senha temporária.
- Conectividade com a internet para instalar pacotes via apt ou ferramenta equivalente.

## 1. Instalação do servidor SSH

Nesta etapa, o objetivo é garantir que o serviço OpenSSH esteja instalado e atualizado no servidor.

### Comandos a serem executados no servidor

```bash
# Atualiza a lista de pacotes do repositório
sudo apt update

# Instala o servidor OpenSSH
sudo apt install openssh-server -y
```

O OpenSSH é a ferramenta principal para login remoto em sistemas Linux. Esses comandos garantem que a versão suportada pela distribuição esteja instalada corretamente.

## 2. Configuração do servidor SSH

Para reforçar a segurança, é recomendável ajustar o arquivo de configuração padrão do serviço SSH.

### Comandos a serem executados no servidor

```bash
# Faz um backup do arquivo original antes de alterar a configuração
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Edita o arquivo de configuração ou cria um arquivo dedicado em /etc/ssh/sshd_config.d/
sudo nano /etc/ssh/sshd_config.d/99-custom-security.conf
```

### Parâmetros recomendados

```text
# Desativa o login do usuário root por segurança
PermitRootLogin no

# Desativa a autenticação por senha (faça isso apenas após configurar a chave SSH)
PasswordAuthentication no

# Restringe o acesso a um usuário específico (opcional)
AllowUsers <USUARIO>
```

Depois de salvar as alterações, reinicie o serviço para aplicar as configurações:

```bash
sudo systemctl restart ssh
```

## 3. Conceitos básicos de SSH e chaves

Para substituir o uso de senhas vulneráveis, será utilizado um par de chaves SSH.

- O algoritmo Ed25519 é uma implementação moderna de assinatura de curva elíptica, oferecendo boa segurança e desempenho superior em comparação a algoritmos mais antigos, como RSA ou DSA.
- A chave privada fica armazenada no computador cliente e deve permanecer protegida.
- A chave pública deve ser copiada para o servidor e colocada em `~/.ssh/authorized_keys` do usuário autorizado.

### Diferença entre chave pública e privada

- Chave privada: é a identidade digital do usuário. Ela nunca deve ser compartilhada nem commitada em repositórios Git.
- Chave pública: pode ser distribuída para servidores e utilizada para validar a identidade da chave privada sem expor o segredo correspondente.

A referência oficial para o processo de geração de chaves pode ser consultada em: https://www.ssh.com/academy/ssh/keygen

## 4. Geração da chave SSH no cliente

No computador local, execute o comando abaixo para gerar o par de chaves.

### Comandos a serem executados no cliente

```bash
# O parâmetro -t define o algoritmo e -C adiciona um comentário de identificação
ssh-keygen -t ed25519 -C "<SEU_EMAIL_OU_COMENTARIO>"
```

Durante a execução, o terminal pode solicitar algumas informações:

- Local do arquivo: pressione Enter para aceitar o caminho padrão `~/.ssh/id_ed25519`.
- Passphrase: digite uma senha forte e pressione Enter. Essa etapa é recomendada porque protege a chave privada no disco, exigindo a senha sempre que ela for utilizada.

### Envio da chave pública para o servidor

Para que o servidor autorize o acesso, envie a chave pública com o utilitário abaixo:

```bash
ssh-copy-id <USUARIO>@<IP_DO_SERVIDOR>
```

Esse comando pode solicitar a senha atual do servidor pela última vez para autorizar a cópia da chave pública.

## 5. Validação da conexão

Depois de instalar a chave pública e reiniciar o serviço SSH no servidor, valide a conexão a partir do computador local.

```bash
ssh <USUARIO>@<IP_DO_SERVIDOR>
```

### Resultados esperados

- O servidor não deve solicitar a senha do usuário `<USUARIO>`.
- Se a passphrase foi configurada, o sistema local solicitará a senha para desbloquear a chave privada.
- O login deve ser concluído com sucesso, abrindo o prompt de comando do servidor.

## 6. Troubleshooting

Se ocorrerem problemas durante a conexão, verifique os pontos a seguir.

### Permission denied (publickey)

O servidor recusou a conexão. Confirme se a chave pública foi inserida corretamente no arquivo `~/.ssh/authorized_keys` do servidor.

Também é possível que a autenticação por senha esteja desativada e a máquina local não esteja enviando a chave correta.

### Permissões incorretas de pasta ou arquivo

O OpenSSH é rigoroso com as permissões de diretórios e arquivos. No servidor, verifique o seguinte:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### Serviço não iniciado ou conexão recusada

Verifique o status do serviço no servidor:

```bash
sudo systemctl status ssh
```

Se houver erro no arquivo de configuração, teste a sintaxe com:

```bash
sudo sshd -T
```

### WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!

Esse aviso pode aparecer se o servidor foi reinstalado, formatado ou se outro host passou a responder pelo mesmo endereço. Remova a entrada antiga localmente com:

```bash
ssh-keygen -R <IP_DO_SERVIDOR>
```

## 7. Segurança e boas práticas

Para manter a integridade do ambiente, siga as recomendações abaixo:

- Nunca compartilhe a chave privada (`id_ed25519`). Somente a chave com extensão `.pub` deve ser distribuída.
- Sempre utilize uma passphrase para proteger a chave privada em caso de perda ou roubo do dispositivo.
- Não exponha configurações de chaves, senhas de banco de dados ou tokens de API em repositórios Git.
- Utilize um arquivo `.gitignore` adequado para ignorar diretórios e arquivos sensíveis, como `*.pem`, `id_*` e `.env`.
- Revise este documento antes de publicar ou fazer commit para garantir que nenhum dado sensível real tenha substituído os placeholders.

## 8. Referências

- SSH.com — SSH Keygen: https://www.ssh.com/academy/ssh/keygen