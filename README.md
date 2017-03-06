git clone https://github.com/mepps/zendesk-export.git

create .env
```
SMTP_USER=
SMTP_PASSWORD=
SMTP_ADDRESS=
ZENDESK_URL=
```

run `rackup config.ru`

navigate to localhost:9292

get api token from Zendesk and enter username and token

NOTE: Based on Zendesk which uses Google login so assumes username is also email address
