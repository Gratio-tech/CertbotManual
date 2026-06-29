# Manual Certbot scripts for Reg.ru
Пакет shell-скриптов для ручного обновления сертификатов certbot с использованием DNS-провайдера Reg.ru

Данные скрипты необходимы в случаях, когда домен для которого выпускаются сертификаты скрыт за VPN и
недоступен из публичной сети. Есть поддержка отправки уведомлений в Telegram.

**ВАЖНО** Скрипты репозитория ожидают, что креды для доступа к DNS по дефолту хранятся в файле
`/etc/example.conf`, для безопасности рекомендуется переименовать его и поправить путь к нему во всех
скриптах если вы клонируете данный пакет.

# Скрипты пакета и их назначение
- acme-notify.sh — хелпер отправляющий уведомления в телеграм
- deploy-success.sh — хук, вызывающийся после успешного обновления сертификата
- manual-cert-renew.sh — ручное обновление сертификата
- regru-auth.sh — основной хук, выполняющий авторизацию и добавление записей через API Reg.ru
- regru-cleanup.sh — хук, подчищающий записи, использованные для выпуска сертификатов
- remove-txt.sh — ручное удаление всех TXT записей (нужно для )
- example.conf —

## Подготовка
Для автоматического управления TXT-записями рекомендуется вместо основоного пароля от аккаунта Reg.ru
выпустить "альтернативный API-пароль" в [настройках API](https://www.reg.ru/user/account/settings/api/),
а также ограничить список IP с которых можно использовать апишку.


## Команды запуска

```bash
git clone https://github.com/Gratio-tech/CertbotManual.git /opt/CertbotManual
chmod +x /opt/CertbotManual/*.sh
cp /opt/CertbotManual/example.conf /etc/example.conf
chmod 600 /etc/example.conf

# Первичный выпуск сертификата, а также ручной перевыпуск
/opt/CertbotManual/manual-cert-renew.sh

# Указать свой файл конфига
CERTBOT_MANUAL_CONFIG=/etc/manual.conf /opt/CertbotManual/manual-cert-renew.sh

```
