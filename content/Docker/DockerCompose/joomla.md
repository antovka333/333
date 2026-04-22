## Docker compose проект c Joomla

**Joomla!** (произносится «джу́мла») — бесплатная система управления контентом (CMS) с открытым исходным кодом, написанная на **PHP** и **JavaScript**. Использует в качестве хранилища базы данных **MySQL** или другие реляционные СУБД

(админка и фронтэнд работает, но заюзать подробней пока не успел)

Перед началом работы над этим проектом, проверье другие запущенные у вас **docker-compose** приложения:
```shell
docker compose ls
```
их лучше остановить, чтобы снизить риск возникновения конфликтов использования портов!

### 1. Создание проекта на Joomla

Создаём каталог проекта
```shell
mkdir joomla-docker
```
Переходим в каталог проекта
```shell
cd joomla-docker
```

### 2. Файл настроек композера `docker-compose.yml`

Создаём и редактируем файл настроек композера средствами **VS Code** или через **Git-Bash**
```yml
services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: joomla
    ports:
      - "3308:3306"
  joomla:
    image: joomla:4-apache
    depends_on:
      - db
    environment:
      JOOMLA_DB_HOST: db
      JOOMLA_DB_USER: root
      JOOMLA_DB_PASSWORD: root
      JOOMLA_DB_NAME: joomla
    ports:
      - "8082:80"
```

Доступ к сайту:

- [Joomla сайт: http://localhost:8082](http://localhost:8082)
- [MySQL: localhost:3307](localhost:3307)


### 3. Установка Joomla

1. Выполнить установку **Joomla**
1. Войти в админ-панель

### 4. Работа с проектом в Docker

Находясь в каталоге проекта, выполнить:

Запуск всех сервисов
```shell
docker compose up -d
```
Проверка статуса
```shell
docker compose ps -a
```
Просмотр логов **Joomla**
```shell
docker compose logs -f joomla
```
Проверьте логи **MySQL**
```shell
docker compose logs db
```
Проверьте сеть
```shell
docker network inspect joomla-docker_joomla-network
```Пересоздайте контейнеры
```shell
docker compose down -v
```
и
```shell
docker compose up -d
```

### Возможные проблемы

```
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint joomla-mysql (269d5375c5e04cc699cae01dc80c527147a5e18c868cc0e8ace67552aad6deb9): Bind for 0.0.0.0:3306 failed: port is already allocated
```

Решение: поменять порт для коннекта с БД

Находясь в каталоге проекта, выполнить:

Остановить текущий композер
```shell
docker compose down
```
Поменять порт
```shell
sed -i 's/3306:3306/3307:3306/' docker-compose.yml
```
Снова запустить
```shell
docker compose up -d
```

### 5. Удалить композер проекта

Переходим в папку проекта
```shell
cd joomla-docker
```
Останавливаем и удаляем контейнеры и **volumes**
```shell
docker compose down -v
```
Выходим из каталога проекта
```shell
cd ..
```
Удаляем папку проекта через `sudo`, если в **Linux**. Для **Windows** без `sudo`
```shell
rm -rf joomla-docker
```

> Если вы обнаружили ошибку в этом тексте - сообщите пожалуйста автору!
