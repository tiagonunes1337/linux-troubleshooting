# Instalação Linux — Lenovo ThinkCentre Edge 72 (diagnóstico de boot)

Descrição

Durante a instalação do Linux Mint em um Lenovo ThinkCentre Edge 72 houve um comportamento inesperado: a instalação concluía corretamente, mas após algumas reinicializações a BIOS não localizava o carregador de inicialização e exibia o erro:

```
1962: No Operating System Found
```

Essa falha indicou possível inconsistência nas variáveis persistidas da BIOS/NVRAM que afetava a identificação do carregador de boot (GRUB).

---

## Sintomas

- Linux Mint instala com sucesso.
- Primeiro boot pós-instalação funciona.
- Em reinicializações subsequentes a BIOS não encontra o sistema operacional.
- Erro mostrado no POST: `1962: No Operating System Found`.
- HD é detectado no setup da BIOS.
- Windows 10 inicializa normalmente na mesma máquina.

---

## Testes realizados

### 1) Tabela de partição e modo de boot

- GPT + UEFI: instalação concluída, mas falha no boot após reinicialização.
- MBR + Legacy: comportamento inicial similar até a limpeza das configurações da BIOS.

### 2) Isolamento de hardware

O disco com Linux foi conectado a outra máquina (LGA 775) em MBR/Legacy e inicializou normalmente — confirmando que a mídia e a instalação estavam válidas. O problema estava relacionado ao comportamento do firmware do ThinkCentre Edge 72 durante o processo de inicialização.

---

## Ação corretiva: Reset de CMOS (procedimento)

Observação: realizar este procedimento apenas se você estiver confortável abrindo a máquina. Desconecte a alimentação e siga as recomendações do fabricante.

Passos resumidos:

1. Desconectar a fonte de alimentação.
2. Mover o jumper `CLR_CMOS` da posição normal (pinos 1-2) para a posição de reset (pinos 2-3) — conforme manual da placa.
3. Ligar a máquina brevemente para garantir que as variáveis sejam limpas.
4. Desligar e recolocar o jumper na posição original.
5. Ligar e entrar no setup da BIOS para restaurar/ajustar configurações.

Efeitos observados:

- Restauro das configurações padrão da BIOS.
- Possível limpeza de variáveis de boot persistentes que impediam o GRUB de ser encontrado.

---

## Configuração final que resolveu o caso

- BIOS: versão original F1KT27AUS
- Boot Mode: Legacy Only
- SATA Mode: AHCI
- Particionamento: MBR (msdos), `ext4` na partição raiz (`/dev/sda1`)
- GRUB instalado no MBR do disco (`/dev/sda`)

Após o reset e reinstalação/configuração em Legacy+MBR, o Linux Mint 21.3 Cinnamon 64-bit passou a inicializar consistentemente.

---

## Comandos úteis (verificação e reparo)

Para analisar o disco e o esquema de partições:

```bash
sudo lsblk -f
sudo fdisk -l /dev/sda
```

Se precisar reinstalar o GRUB em modo Legacy (exemplo): monte a partição raiz e instale o GRUB no MBR:

```bash
sudo mount /dev/sda1 /mnt
sudo grub-install --target=i386-pc --boot-directory=/mnt/boot /dev/sda
sudo chroot /mnt update-grub
```

Nota: adapte os dispositivos/mountpoints ao seu ambiente. Em sistemas UEFI/EFI use `grub-install` adequado (`--target=x86_64-efi`) e partição EFI.

---

## Resultado

Resetar o CMOS e usar Legacy+MBR resolveu o problema nesta máquina específica; o sistema passou a inicializar sem apresentar o erro 1962 após várias reinicializações.

---

## Aprendizados técnicos

- Reset de CMOS pode limpar variáveis persistentes que causam falhas no reconhecimento do carregador de boot.
- Nem todo problema de boot exige atualização de BIOS; restaurar as configurações do firmware pode ser suficiente.
- Hardware OEM mais antigo pode apresentar comportamentos diferentes com Linux vs Windows.
- O erro 1962 (Lenovo) indica que a BIOS não encontrou um sistema inicializável — verificar modo de boot, configuração do firmware e presença do carregador de boot.

---

## Próximos passos

Este equipamento será utilizado como homelab para:

- AdGuard Home
- Servidor de arquivos (NAS)
- Docker/containers
- Testes de infraestrutura Linux
- Automações com scripts

## Referências / links úteis

- Verifique o manual da placa-mãe/lenovo para a posição do jumper `CLR_CMOS`.
- Documentação do GRUB: https://www.gnu.org/software/grub/


