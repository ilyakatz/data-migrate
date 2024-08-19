# Changelog

# 11.0.0rc
- Remove Ruby 3.0 from build matrix
- Support Rails 7.2.0 https://github.com/ilyakatz/data-migrate/pull/312
- Update gemfile.lock builds

## 9.4.2
- Fix db:prepare:with_data task

## 9.4.1
- Add db:prepare task

## 9.4.0
- Reset model schema cache before each data migration https://github.com/ilyakatz/data-migrate/pull/307
- Run load_config rake task before db:migrate:with_data https://github.com/ilyakatz/data-migrate/pull/308

## 9.3.0
- Improve with_data Rake task for multiple database https://github.com/ilyakatz/data-migrate/pull/296

## 9.2.0
- Support Rails 7.1 https://github.com/ilyakatz/data-migrate/pull/278
- Build and test against 7.1.0.rc1 https://github.com/ilyakatz/data-migrate/pull/286

## 9.1.0

- Fix a bug that caused `schema_sha1` in `ar_internal_metadata` to be reset to the `data_schema.rb` file. (#272)
- Remove the need for empty data_schema files for non-primary databases. (#273)

## [YANKED] 10.0.3.rc

- Remove all travis references [leoarnold](https//:github.com/leoarnold)
- Changing to rc because of ongoing discussion how to properly handle multiple database environments

## [YANKED] 10.0.2

Change "rails" dependencies to "railties"

## [YANKED] 10.0.1

- Bug fix for Rails 6 config [chaunce](https//:github.com/chaunce)
- Railties bug fix by [opti](https://github.com/opti)

## [YANKED] 10.0.0

Releasing 10.0.0

!!! Breaking changes !!!

- This version introduces a breaking change which may lead to undesired
behavior in multi-database environments. See https://github.com/ilyakatz/data-migrate/issues/181

## [YANKED] 10.0.0.rc1

- Changes by [chaunce](https//:github.com/chaunce)
- Multiple databases support
- Refactor to clean things up
- Deprecate rails 5.2 support for real

## 9.0.0

Ruby 3.2 support [mehanoid](https://github.com/mehanoid)
Rails 5.2 is no longer supported

## 8.5.0

Allow custom templates [bazay](https://github.com/bazay)

## 8.4.0

Avoid Globally Accessible Functions for All Rake Tasks [berniechiu](https://github.com/berniechiu)

## 8.3.0

Add delegation to exists? for use by third parties [foxondo](https://github.com/foxondo)

## 8.2.0

Delegate to anonymous subclass of AR::SchemaMigration [foxondo](https://github.com/foxondo)

## 8.1.1

Revert 8.1.0 changes

## 8.1.0

Avoid globally accessible functions for all rake tasks [berniechiu](https://github.com/berniechiu)
fixed `db:migrate:with_data` to compare data schema versions correctly [cadactive](https://github.com/cadactive)

## 8.0.0.rc2

Bug fixes [gdott9](https://github.com/gdott9)

## 8.0.0.rc1
Add support for Rails 7
Removed support for Rails versions below 5.2. Now are supported only versions Rails 5.2 and up

## 7.0.2

Remove magic comment in migration files [y-yagi](https://github.com/y-yagi)
User frozen string [jonnay](https://github.com/jonnay)
## 7.0.1
Use SchemaMigration.migrations_paths in main rake task [lewhit](https://github.com/lewhit)

## 6.8.0

Specify database name for migrations_paths [lewhit](https://github.com/lewhit)
## 6.7.0

Add configuration for which database name is to be used for database migrations [lewhit](https://github.com/lewhit)
Add tests for Rails 6.1 [lewhit](https://github.com/lewhit)
Migrations files should end only in .rb [kroehre](https://github.com/kroehre)

## 6.6.2
## 6.6.1

configs_for deprecation notice [borama](https://github.com/borama)
## 6.6.0

Allow data dump connection to be configured [lewhit](https://github.com/lewhit)

## 6.4.0

Add primary key to data_migrations table [aandis](https://github.com/aandis)

## 6.3.0

Add `abort_if_pending_migrations` rake tasks [tomgia](https://github.com/tomgia)

## 6.2.0

Add `rake data:schema:load` [timkrins](https://github.com/timkrins)

## 6.1.0

Fixing `rake db:schema:load:with_data` for Rails 6

Note:

Rails 5.0 is no longer maintained. The gem will still work but it is not being
actively tested.

## 6.0.5

Fixing `needs_migration?` method for Rails 5.2 and up [EnomaDebby](https://github.com/EnomaDebby)

## 6.0.4.beta

Fix rolling back schema migrations failing for Rails 5.2 and above

## 6.0.3.beta

Compatiblity with Rails 6 RC2 [y-yagi](https://github.com/y-yagi)

## 6.0.1.beta

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
