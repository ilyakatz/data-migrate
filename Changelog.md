# Changelog

## 6.0.1
Fix migrations being generated in wrong folder

## 6.0.0

Support for Rails 6
No longer supporting Rails 4.2

## 5.3.3

Ruby 2.2 and 2.3 are no longer actively validated with tests since they are both EOL

## 5.3.2

Fix capistrano migration tasks to only skip migrations if there are no changes in the db/data and db/migrate folders

## 5.3.1

Change database task to use data_migrations_path_configuration

## 5.3.0

Add support to configure data migration path

## 5.1.0

Fixes to `db:schema:load:with_data` + `db:structure:load:with_data` definition, thanks to [craineum](https://github.com/craineum)

## 5.0.0

Remove support for legacy migrations (from v2).

**IMPORTANT**: If you used this gem from before version 2, make sure to run migration script

```
DataMigrate::LegacyMigrator.new.migrate
```

**Failure to do so may cause re-running old migrations**

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
