## Docker compose проект c drawDB

**DrawDB** — бесплатный, простой и интуитивно понятный редактор схем баз данных и генератор SQL прямо в браузере

[Ссылка drawDB на Github](https://github.com/drawdb-io/drawdb)

Перед началом работы над этим проектом, проверье другие запущенные у вас **docker-compose** приложения:
```shell
docker compose ls
```
их лучше остановить, чтобы снизить риск возникновения конфликтов использования портов!

### 1. Получить drawDB

Клонируем репозиторий:
```shell
git clone https://github.com/drawdb-io/drawdb
```

Переходим в локальную папку склонированного репозитория
```shell
cd drawdb/
```

### 2. Запустить drawDB

Запускаем проект
```shell
docker compose up -d
```

[Открыть drawDB локально в браузере](http://localhost:5173/)

### 3. Удалить проект

Остановить контейнер с удалением данных
```shell
docker compose down -v
```

Проверить, не запущен ли удаляемый контейнер
```shell
docker ps -a
```
и
```shell
docker compose ps -a
```
Получить id образа
```shell
docker images
```
Удалить образ
```shell
docker rmi 1b3a22d17cb6
```
Удалить каталог проекта
```shell
rm -rf drawdb
```

> Если вы обнаружили ошибку в этом тексте - сообщите пожалуйста автору!
