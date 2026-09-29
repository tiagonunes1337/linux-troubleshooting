# 1. Desmonta a partição caso tenha montado em 'ro'
sudo umount /mnt/jogos_steam

# 2. Limpa o dirty bit e reseta os sinalizadores NTFS
sudo ntfsfix -b -d /dev/sda2

# 3. Remonta com permissões totais de leitura, escrita e execução
sudo mount -t ntfs-3g -o rw,uid=$(id -u),gid=$(id -g),umask=000,exec /dev/sda2 /mnt/jogos_steam

# 4. Testa a gravação (não deve retornar nenhum erro)
touch /mnt/jogos_steam/teste_rw.tmp && rm /mnt/jogos_steam/teste_rw.tmp