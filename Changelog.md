Changelog
=========

## 3.1.0

Rails 5.0 support thanks to
[jturkel](https://github.com/jturkel) and [gacha](https://github.com/gacha)

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
