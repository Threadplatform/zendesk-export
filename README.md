git clone https://github.com/mepps/zendesk-export.git

create .env
```
SMTP_USER=
SMTP_PASSWORD=
SMTP_ADDRESS=
ZENDESK_BASE=[customized base of zendesk url]
BRAND_FAVICON_URL=
BRAND_IMAGE_URL=
```

run `rackup config.ru`

navigate to localhost:9292

get api token from Zendesk and enter username and token

NOTE: Based on Zendesk set using Google login so assumes username is also email address
