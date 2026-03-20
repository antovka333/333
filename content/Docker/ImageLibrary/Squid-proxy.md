## Прокси сервер Squid proxy

> Никогда в разработке не используйте русские имена файлов и каталогов!
> Никогда в разработке не используйте пробелы и спец.символы в именах файлов и каталогов!

1. Запустить Squid proxy

в **Windows Powershell**
```shell
docker run -d ^
  --name squid-proxy ^
  -p 3128:3128 ^
  ubuntu/squid:latest
```

в **Linux/WSL 2.0/Mac**
```shell
docker run -d \
  --name squid-proxy \
  -p 3128:3128 \
  ubuntu/squid:latest
```
2. [Настройте браузер использовать proxy: localhost:3128](localhost:3128)

> Если вы обнаружили ошибку в этом тексте - сообщите пожалуйста автору!
