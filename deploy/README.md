# Свой Garmin MCP на сервере DigitalOcean

Схема: Claude → `https://<IP>.sslip.io/<секрет>/mcp` → Caddy (HTTPS, подставляет токен) → garmin-mcp → Garmin Connect.

Удаление и правка данных в Garmin отключены. Чтение и отправка тренировок на часы работают.

Все наши файлы лежат в папке `deploy/` ветки `deploy`. Файлы оригинального проекта не тронуты, поэтому обновления из основного репозитория вливаются без конфликтов.

## 1. На сервере

```bash
git clone -b deploy https://github.com/AlexTibet/garmin_mcp.git
cd garmin_mcp/deploy
./setup.sh     # создаст .env (он в .gitignore) и покажет адрес коннектора
```

Откройте порты 80 и 443, если включён файрвол:

```bash
ufw allow 80,443/tcp
```

В DigitalOcean проверьте ещё раздел Networking → Firewalls, если пользуетесь им.

## 2. Один раз войти в Garmin

```bash
docker compose build
docker compose run --rm --entrypoint garmin-mcp-auth garmin-mcp
```

Введите email, пароль и код MFA, если он включён. Токены сохранятся в Docker-томе, пароль на сервере не хранится.
Токены живут около 6 месяцев. Когда истекут, повторите эту команду с `--force-reauth` в конце.

## 3. Запуск

```bash
docker compose up -d
docker compose logs -f caddy      # ждём "certificate obtained successfully"
```

## 4. Подключение к Claude

claude.ai → Настройки → Коннекторы → «Добавить свой коннектор» (Add custom connector):

- Название: `Garmin`
- URL: адрес, который вывел `./setup.sh` (`https://…sslip.io/…/mcp`). Чтобы увидеть его ещё раз, запустите `./setup.sh` повторно.
- OAuth-поля оставьте пустыми.

После этого коннектор работает и в мобильном приложении.

## Обновление

1. На GitHub в форке переключитесь на ветку `main` и нажмите **Sync fork**.
2. На сервере выполните:

```bash
cd garmin_mcp
git pull --no-rebase --no-edit origin main
cd deploy && docker compose up -d --build
```

## Обслуживание

- Проверить вход в Garmin: `docker compose exec garmin-mcp python -c "import urllib.request;print(urllib.request.urlopen('http://localhost:8000/readyz').read())"`
- Если адрес коннектора утёк: удалите `.env`, запустите `./setup.sh`, затем `docker compose up -d --force-recreate` и обновите URL в Claude.

## Если что-то не так

- Сертификат не выдаётся: закрыт порт 80 или 443, либо его занимает другой сервис (`ss -tlnp | grep -E ':80|:443'`).
- Claude пишет об ошибке подключения: проверьте `docker compose logs caddy` и `docker compose logs garmin-mcp`.
- Garmin отвечает 401 или 403: повторите шаг 2 с `--force-reauth`.
