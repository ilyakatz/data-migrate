Data Migrate
====

Run data migrations alongside schema migrations.

Data migrations are stored in db/data. They act like schema
migrations, except they should be reserved for data migrations. For
instance, if you realize you need to titleize all yours titles, this
is the place to do it.

Why should I use this?
----------------------

Its seems when a project hits a certain size, I get to manipulate data
outside the application itself.  Changing defaults, new validations,
one-to-one to one-to-many... I found it a pain and dodgy to have to
step up migrations one by one, run a ruby script of some sort, then
resume migrations.  It tanks a lot of the automation of deploy.

If you don't use the one off scripts, you could do it as a regular
migration.  It'd be much better to keep concerns separate. The benefit
of having them separate has to do with your data model.

For instance, lets take an absurd example, to illustrate: You have
your infamous [Rails blog](http://media.rubyonrails.org/video/rails-0-5.mov)
that has posts with many comments.  After some use, you decide you are
going to be a trend setter, and want only one comment per post, and
just the text. "Frist!" rules the day. Given that you:
- write a migration to add a comment column to Post
- write a migration to move the contents of the first comments to the Post
- drop the column_id column from Post
- drop the Comment model
- fix all your test/controller/view mojo.

You've just got bit.  When you rake setup:development, the mess gets
mad at you after it creates your database, and starts cranking through
migrations.  It gets to the part where you iterate over the comments
and it blows up.  You don't have a comment model anymore for it to
even try and get 'all' from.  You think you are smarter, and wrap the
AR call in a conditional based on the environment. That's fine until
you get that QA gal, and she wants her own thing. Then the UI people
get tired of waiting for the full stack to load on page refreshes, so
you have to edit past migrations...

With Data Migrate, you have the control.  You can generate your
migrations as schema or data as you would as your work flow. For
setting tasks that don't require any intermediate AR activity, like
dev and test, you stick with db:migrate.  For your prod, and qa, you
change their scripts to `db:migrate:with_data`.  Of course you want to
test your migration, so you have the choice of `db:migrate:with_data` or
`data:migrate` to just capture that data change.

What's it do?
-------------

Data migrations are stored in db/data. They act like schema
migrations, except they should be reserved for data migrations. For
instance, if you realize you need to titleize all yours titles, this
is the place to do it. Running any of the provided rake tasks also
creates a data schema table to mirror the usual schema migrations
table to track all the goodness.

Data migrations can be created at the same time as schema migrations,
or independently.  Database (db:) tasks have been added and extended
to run on data migrations only, or in conjunction with the schema
migration.  For instance, `rake db:migrate:with_data` will run both
schema and data migrations in the proper order.

Note: If a data and schema migration share the same version number, schema gets precedence when migrating up. Data does down.

Rails 3 and Ruby 1.9
--------------------

Data Migrate is Rails 3.0.0 - 3.0.7, and Ruby 1.9 compatible

Installation
------------
Add the gem to your project

    # Gemfile
    gem 'data_migrate'

Then `bundle install` and you are ready to go.

So you know, when you use one of the provide rake tasks, a table
called 'data_migrations' will be created in your database. This
is to mirror the way the standard 'db' rake tasks work. If you've
installed previous to v1.1.0, you'll want to delete the
'create\_data\_migrations_table' migration.

Usage
-----

### Generating Migrations

You can generate a data migration as you would a schema migration:

    rails g data_migration add_this_to_that

By default, the migration also generates a schema migration by the same name.
This allows you to do things like:

    rails g data_migration add_this_to_that this:string

If you need a data only migration, either run it as such, with the skip-schema-migration flag:

    rails g data_migration add_this_to_that --skip-schema-migration


### Rake Tasks

    $> rake -T data
    rake data:forward                 # Pushes the schema to the next version (specify steps w/ STEP=n).
    rake data:migrate                 # Migrate the database through scripts in db/data.
    rake data:migrate:down            # Runs the "down" for a given migration VERSION.
    rake data:migrate:redo            # Rollbacks the database one migration and re migrate up (options: STEP=x, VERSION=x).
    rake data:migrate:status          # Display status of data migrations
    rake data:migrate:up              # Runs the "up" for a given migration VERSION.
    rake data:rollback                # Rolls the schema back to the previous version (specify steps w/ STEP=n).
    rake data:version                 # Retrieves the current schema version number for data migrations
    rake db:forward:with_data         # Pushes the schema to the next version (specify steps w/ STEP=n).
    rake db:migrate:data              # Migrate the database through scripts in db/data/migrate.
    rake db:migrate:down:with_data    # Runs the "down" for a given migration VERSION.
    rake db:migrate:redo:with_data    # Rollbacks the database one migration and re migrate up (options: STEP=x, VERSION=x).
    rake db:migrate:status:with_data  # Display status of data and schema migrations
    rake db:migrate:up:with_data      # Runs the "up" for a given migration VERSION.
    rake db:migrate:with_data         # Migrate the database data and schema (options: VERSION=x, VERBOSE=false).
    rake db:rollback:with_data        # Rolls the schema back to the previous version (specify steps w/ STEP=n).
    rake db:version:with_data         # Retrieves the current schema version numbers for data and schema migrations `

Tasks work as they would with the 'vanilla' db version.  The 'with_data' addition to the 'db' tasks will run the task in the context of both the data and schema migrations.  That is, `rake db:rollback:with_data` will check to see if it was a schema or data migration invoked last, and do that.  Tasks invoked in that space also have an additional line of output, indicating if the action is performed on data or schema.

With 'up' and 'down', you can specify the option 'BOTH', which defaults to false. Using true, will migrate both the data and schema (in the desired direction) if they both match the version provided.  Again, going up, schema is given precedence. Down its data.

For more example, assume you have the 2 files:
  db/migrate/20110419021211_add_x_to_y.rb
  db/data/20110419021211_add_x_to_y.rb

Running `rake db:migrate:up:with_data VERSION=20110419021211` would execute the 'db/migrate' version.
Running `rake db:migrate:up:with_data VERSION=20110419021211` would execute the 'db/migrate' version, followed by the 'db/data' version.

Going down instead of up would be the opposite.

`rake db:migrate:status:with_data` provides and additional column to indicate which type of migration.

Thanks
------
[Jeremy Durham](http://jeremydurham.com/) for fleshing out the idea with me, and providing guidance.
You!  Yes, you. Thanks for checking it out.
