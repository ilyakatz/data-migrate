Changelog
=========

## 4.0.0

Support for Rails 5.2
Deprecated support for Rails 4.1
Internal changes to make data-migrate behavior more similar to Rails migrations

## 3.5.0

Deprecated support for rails 4.0
Improvements to timestamped migrations, thanks to [Pierre-Michard](https://github.com/Pierre-Michard)

## 3.4.0
`rake data:migrate:status` to return result in chronological order
## 3.3.1
Regression fix, thanks to [subakva](https://github.com/subakva)

## 3.3.0
The concept of schema:dump to data migrations, thanks to
[tobyndockerill](https://github.com/tobyndockerill)

## 3.2.1

data_migrate table into rails schema dump, thanks to
[jturkel](https://github.com/jturkel) 


## 3.2.0
- Add support for Rails 5.1
- No longer testing EOL rubies

## 3.1.0

Rails 5.0 support thanks to
[jturkel](https://github.com/jturkel) and [abreckner](https://github.com/abreckner)

## 3.0.1

([gacha](https://github.com/gacha)) Capistrano fixes

## 3.0.0

`--skip-schema-migration` removed deprecated. This gem will no longer generate schema
migrations. It still supports running schema/data migrations with one command.

## 2.2.0

([bilby91](https://github.com/bilby91)) Capistrano support

## 2.1.0

User `Rails.application.config.paths["db/migrate"]` instead of hard coded
path to db migrations
