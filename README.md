# Thredded [![Code Climate](https://codeclimate.com/github/thredded/thredded/badges/gpa.svg)](https://codeclimate.com/github/thredded/thredded) [![Travis-CI](https://api.travis-ci.org/thredded/thredded.svg?branch=master)](https://travis-ci.org/thredded/thredded/) [![Test Coverage](https://codeclimate.com/github/thredded/thredded/badges/coverage.svg)](https://codeclimate.com/github/thredded/thredded/coverage) [![Gitter](https://badges.gitter.im/thredded/thredded.svg)](https://gitter.im/thredded/thredded?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge) [![Stories in Ready](https://badge.waffle.io/thredded/thredded.svg?label=ready&title=waffle.io)](http://waffle.io/thredded/thredded)

### /Users/benjaminkies/Workspace/SimpleFractal

Changes made for wcai
 - Added columns to the preferences table:
  cp /thredded/db/upgrade_migrations/20160825151050_add_weekly_digest_to_thredded_user_preferences.rb to your migrations and run it.

_Thredded_ is a Rails 4.2+ forum/messageboard engine. Its goal is to be as simple and feature rich as possible.

Some of the features currently in Thredded:

* Markdown post formatting with some BBCode support (by default).
* (Un)read posts tracking.
* Email notifications, topic subscriptions, @-mentions, per-messageboard notification settings.
* Private group messaging.
* Full-text search using the database.
* Pinned and locked topics.
* List of currently online users, for all forums and per-messageboard.
* Flexible permissions system.
* Basic moderation.
* Lightweight default theme configurable via Sass.

<a href='https://pledgie.com/campaigns/27480'><img alt='Click here to lend your support to: Thredded and make a donation at pledgie.com !' src='https://pledgie.com/campaigns/27480.png?skin_name=chrome' border='0' ></a>

<img src="http://emoji.fileformat.info/gemoji/point_up.png" width="24"> If you are so inclined, donating to the project will help aid in its development


| ![screenshot-messageboards] | ![screenshot-topics] |
|----------------------------|----------------------------|
| ![screenshot-topic]  | ![screenshot-new-private-topic-dark] |

[screenshot-messageboards]: https://cloud.githubusercontent.com/assets/216339/14379803/d608d782-fd73-11e5-9d8e-1f282ea66fab.png
[screenshot-topics]: https://cloud.githubusercontent.com/assets/216339/14379804/d77db060-fd73-11e5-9a4a-9376ca409756.png
[screenshot-topic]: https://cloud.githubusercontent.com/assets/216339/14379805/d8ecf32a-fd73-11e5-8734-b7faa8b264ee.png
[screenshot-new-private-topic-dark]: https://cloud.githubusercontent.com/assets/216339/14379806/da716a1e-fd73-11e5-90f1-6dbdb708d3d5.png

Thredded works with SQLite, MySQL (v5.6.4+), and PostgreSQL. Thredded has no infrastructure
dependencies other than the database and, if configured in the parent application, the ActiveJob
backend dependency such as Redis. Currently only MRI Ruby 2.2+ is supported. We would love to
support JRuby and Rubinius as well.

If you're looking for variations on a theme - see [Discourse]. However, It is a full rails
application and not an engine like Thredded.

[Discourse]: http://www.discourse.org/

## Installation

Add the gem to your Gemfile:

```ruby
gem 'thredded', '~> 0.6.1'
```

Add the Thredded [initializer] to your parent app by running the install generator.

```console
rails generate thredded:install
```

Copy emoji images to your `public/emoji` directory.

```console
rake thredded:install:emoji
```

Thredded needs to know the base application User model name and certain columns on it. Configure
these in the initializer installed with the command above.

Then, copy the migrations over to your parent application and migrate:

```console
rake thredded:install:migrations db:migrate db:test:prepare
```

Mount the thredded engine in your routes file:

```ruby
mount Thredded::Engine => '/forum'
```

You also may want to add an index to the user name column in your users table.
Thredded uses it to find @-mentions and perform name prefix autocompletion on the private topic form.
Add the index in a migration like so:

```ruby
DbTextSearch::CaseInsensitive.add_index(
    connection, Thredded.user_class.table_name, Thredded.user_name_column, unique: true)
```

### Upgrading an existing install

1) To upgrade the initializer:

```console
rails g thredded:install
```

But then compare this with the previous version to decide what to keep.

2) To upgrade the database (in this example from v0.4 to the v0.5):

```console
cp `bundle show thredded`/db/upgrade_migrations/20160501151908_upgrade_v0_4_to_v0_5.rb db/migrate
rake db:migrate
```

Note that for guaranteed best results you will want to run this with the gem checked out with v0.5.0.

### Migrating from Forem

Are you currently using [Forem]? Thredded provides [a migration][forem-to-thredded] to copy all of your existing data from Forem over
to Thredded.

[forem-to-thredded]: https://github.com/thredded/thredded/wiki/Migrate-from-Forem
[Forem]: https://github.com/rubysherpas/forem

## Views and other assets

### Standalone layout

By default, thredded renders in its own layout.

When using the standalone thredded layout, the log in / sign out links will be rendered in the navigation.
For these links (and only for these links), Thredded makes the assumption that you are using devise as your auth
library. If you are using something different you need to override the partial at
`app/views/thredded/shared/nav/_standalone.html.erb` and use the appropriate log in / sign out path URL helpers.

You can override the partial by copying it into the app:

```bash
mkdir -p app/views/thredded/shared/nav && cp "$(bundle show thredded)/$_/_standalone.html.erb" "$_"
```

### Application layout

You can also use Thredded with the application layout by by setting `Thredded.layout` in the initializer.

In this case, you will also need to include Thredded styles and JavaScript into the application styles and JavaScript.

Add thredded styles to your `application.scss` (see below for customizing the styles):

```scss
@import "thredded";
```

Include thredded JavaScripts in your `application.js`:

```js
//= require thredded
```

Thredded views also provide two `content_tag`s available to yield - `:thredded_page_title` and `:thredded_page_id`.
The views within Thredded pass those up through to your layout if you would like to use them.

### User profile page

Thredded does not provide a user's profile page, but it provides a helper for rendering the user's recent posts
in your app's user profile page.

To use it:

1. Include `Thredded::ApplicationHelper` in the app's helpers module.
2. Render the partial like this:

```erb
<%= render 'thredded/users/posts',
           posts: Thredded.posts_page_view(
               scope: user.thredded_posts.order_newest_first.limit(5),
               current_user: current_user) %>
```

### Customizing views

You can also override any views and assets by placing them in the same path in your application as they are in the gem.
This uses the [standard Rails mechanism](http://guides.rubyonrails.org/engines.html#overriding-views) for overriding
engine views. For example, to copy the post view for customization:

```bash
# Copy the post view into the application to customize it:
mkdir -p app/views/thredded/posts && cp "$(bundle show thredded)/$_/_post.html.erb" "$_"
```

**NB:** Overriding the views like this means that on every update of the thredded gem you have to check that your
customizations are still compatible with the new version of thredded. This is difficult and error-prone.
Whenever possible, use the styles and i18n to customize Thredded to your needs.

#### Empty view partials included for customization

There are 2 empty view partials included in the gem that exist for the purpose of being overridden
in the parent app *if desired*. They are:

* `app/views/thredded/posts_common/form/_before_content.html.erb`
* `app/views/thredded/posts_common/form/_after_content.html.erb`

And are rendered directly before, and directly after the textarea where users type their post
contents. These exist in the case where a messageboard would like to add things like, wysiwyg/wymean
editors, buttons, help links, help copy, further customization for the textarea, etc.

## Theming

The engine comes by default with a light and effective implementation of the
views, styles, and javascript. Once you mount the engine you will be presented
with a "themed" version of thredded.

### Styles

Thredded comes with a light Sass theme controlled by a handful of variables that can be found here:
https://github.com/thredded/thredded/blob/master/app/assets/stylesheets/thredded/base/_variables.scss.

To override the styles, override the variables *before* importing Thredded styles, e.g.:

```scss
// application.scss
$thredded-brand: #9c27b0;
@import "thredded";
```

The `@import "thredded"` directive above will import thredded styles and the [dependencies][thredded-scss-dependencies]
(currently just "select2" from [select2-rails]). If you already include your own styles for any of thredded
dependencies, you can import just the thredded styles alone like this:

```scss
// application.scss
@import "thredded/thredded";
```

If you are writing a Thredded plugin, import the [`thredded/base`][thredded-scss-base] Sass package instead.
The `base` package only defines variables, mixins, and %-placeholders, so it can be imported safely without producing
any duplicate CSS.

[thredded-scss-dependencies]: https://github.com/thredded/thredded/blob/master/app/assets/stylesheets/thredded/_dependencies.scss
[select2-rails]: https://github.com/argerim/select2-rails
[thredded-scss-base]: https://github.com/thredded/thredded/blob/master/app/assets/stylesheets/thredded/_base.scss

### Emails

Thredded sends several notification emails to the users. You can override in the same way as the views.
If you use [Rails Email Preview], you can include Thredded emails into the list of previews by adding
`Thredded::BaseMailerPreview.preview_classes` to the [Rails Email Preview] `preview_classes` config option.

[Rails Email Preview]: https://github.com/glebm/rails_email_preview

## I18n

Thredded is mostly internationalized. It is currently available in English and Brazilian Portuguese. We welcome PRs
adding support for new languages.

If you use thredded in languages other than English, you probably want to add `rails-i18n` to your Gemfile.
Additionally, you will need to require the translations for rails-timeago in you JavaScript,
e.g. for Brazilian Portuguese:

```js
//= require locales/jquery.timeago.pt-br
```

## Permissions

Thredded comes with a flexible permissions system that can be configured per messageboard/user.
It calls a handful of methods on the application `User` model to determine permissions for logged in users, and calls
the same methods on `Thredded:NullUser` to determine permissions for non-logged in users.

### Permission methods

The methods used by Thredded for determining the permissions are described below.

* To customize permissions for logged in users, override any of the methods below on your `User` model.
* To customize permissions for non-logged in users, override these methods on `Thredded::NullUser`.

#### Reading messageboards

1. A list of messageboards that a given user can read:

  ```ruby
  # @return [ActiveRecord::Relation] messageboards that the user can read
  thredded_can_read_messageboards
  ```
2. A list of users that can read a given list of messageboards:

  ```ruby
  # @param messageboards [Array<Thredded::Messageboard>]
  # @return [ActiveRecord::Relation] users that can read the given messageboards
  self.thredded_messageboards_readers(messageboards)
  ```

#### Posting to messageboards

1. A list of messageboards that a given user can post in.

  ```ruby
  # @return [ActiveRecord::Relation<Thredded::Messageboard>] messageboards that the user can post in
  thredded_can_write_messageboards
  ```

2. A list of users that can post to a given list of messageboards.

  ```ruby
  # @param messageboards [Array<Thredded::Messageboard>]
  # @return [ActiveRecord::Relation<User>] users that can post to the given messageboards
  self.thredded_messageboards_writers(messageboards)
  ```

#### Messaging other users (posting to private topics)

A list of users a given user can message:

```ruby
# @return [ActiveRecord::Relation] the users this user can include in a private topic
thredded_can_message_users
```

#### Moderating messageboards

1. A list of messageboards that a given user can moderate:

  ```ruby
  # @return [ActiveRecord::Relation<Thredded::Messageboard>] messageboards that the user can moderate
  thredded_can_moderate_messageboards
  ```
2. A list of users that can moderate a given list of messageboards:

  ```ruby
  # @param messageboards [Array<Thredded::Messageboard>]
  # @return [ActiveRecord::Relation<User>] users that can moderate the given messageboards
  self.thredded_messageboards_moderators(messageboards)
  ```

#### Admin permissions

Includes all of the above for all messageboards:

```ruby
# @return [boolean] Whether this user has full admin rights on Thredded
thredded_admin?
```

### Default permissions

Below is an overview of the default permissions, with links to the implementations:

<table>
<thead>
  <tr>
    <th align="center"></th>
    <th align="center">Read</th>
    <th align="center">Post</th>
    <th align="center">Message</th>
    <th align="center">Moderate</th>
    <th align="center">Administrate</th>
  </tr>
</thead>
<tbody>
<tr>
  <th align="center">Logged in</th>
  <td align="center" rowspan="2"><a href="https://github.com/thredded/thredded/blob/master/app/models/thredded/user_permissions/read/all.rb">
    ✅ All
  </a></td>
  <td align="center"><a href="https://github.com/thredded/thredded/blob/master/app/models/thredded/user_permissions/write/all.rb">
    ✅ All
  </a></td>
  <td align="center"><a href="https://github.com/thredded/thredded/blob/master/app/models/thredded/user_permissions/message/readers_of_writeable_boards.rb">
    Readers of the messageboards<br>the user can post in
  </a></td>
  <td align="center"><a href="https://github.com/thredded/thredded/blob/master/app/models/thredded/user_permissions/moderate/if_moderator_column_true.rb">
    <code>moderator_column</code>
  </a></td>
  <td align="center"><a href="https://github.com/thredded/thredded/blob/master/app/models/thredded/user_permissions/admin/if_admin_column_true.rb">
    <code>admin_column</code>
  </a></td>
</tr>
<tr>
  <th align="center">Not logged in</th>
  <!-- rowspan -->
  <td align="center"><a href="https://github.com/thredded/thredded/blob/master/app/models/thredded/user_permissions/write/none.rb">
    ❌ No
  </a></td>
  <td align="center"><a href="https://github.com/thredded/thredded/blob/master/app/models/thredded/user_permissions/message/readers_of_writeable_boards.rb">
    ❌ No
  </a></td>
  <td align="center"><a href="https://github.com/thredded/thredded/blob/master/app/models/thredded/user_permissions/moderate/none.rb">
    ❌ No
  </a></td>
  <td align="center"><a href="https://github.com/thredded/thredded/blob/master/app/models/thredded/user_permissions/admin/none.rb">
    ❌ No
  </a></td>
</tr>
</tbody>
</table>

### Handling "Permission denied" and "Not found" errors

Thredded defines a number of Exception classes for not found / permission denied errors.
The complete list can be found [here](https://github.com/thredded/thredded/blob/master/app/controllers/thredded/application_controller.rb#L18-L40).

Currently, the default behaviour is to render an error message with an appropriate response code within the Thredded
layout. You may want to override the handling for `Thredded::Errors::LoginRequired` to render a login form instead.
For an example of how to do this, see the initializer.

## Moderation

Thredded comes with two options for the moderation system:

1. Reactive moderation, where posts from first-time users are published immediately but enter the moderation queue
   (default).
2. Pre-emptive moderation, where posts from first-time users are not published until they have been approved.

This is controlled by the `Thredded.content_visible_while_pending_moderation` setting.

Users, topics, and posts can be in one of three moderation states: `pending_moderation`, `approved`, and `blocked`.
By default, new users are `pending_moderation`, and new posts and topics inherit their default moderation_state from
the user's.

When you approve a new user's post, all of their later posts will be approved automatically.

Additionally, users always see their own posts regardless of the moderation state. For blocked users, this means
they might not realize they have been blocked right away.

Blocked users cannot send private messages.

### Disabling moderation

To disable moderation, e.g. if you run internal forums that do not need moderation, run the following migration:

```ruby
change_column_default :thredded_user_details, :moderation_state, 1 # approved
```

## Development

To be more clear - this is the for when you are working on *this* gem.
Not for when you are implementing it into your Rails app.

First, to get started, migrate and seed the database (SQLite by default):

```bash
bundle
# Create, migrate, and seed the development database with fake forum users, topics, and posts:
rake db:create db:migrate db:seed
```

Then, start the dummy app server:

```bash
rake dev:server
```

To run the tests, just run `rspec`. The test suite will re-create the test database on every run, so there is no need to
run tasks that maintain the test database.

Run `rubocop` to ensure a consistent code style across the codebase.

By default, SQLite is used in development and test. On Travis, the tests will run using SQLite, PostgreSQL, SQLite,
and all the supported Rails versions.

### Testing with all the databases and Rails versions locally.

You can also test the gem with all the supported databases and Rails versions locally.

First install PostgreSQL and MySQL, and run:

```bash
script/create-db-users
```

Then, to test with all the databases and the default Rails version (as defined in `Gemfile`), run:

```bash
rake test_all_dbs
```

To test with a specific database and all the Rails versions, run:

```bash
# Test with SQLite3:
rake test_all_gemfiles
# Test with MySQL:
DB=mysql2 rake test_all_gemfiles
# Test with PostgreSQL:
DB=postgresql rake test_all_gemfiles
```

To test all combinations of supported databases and Rails versions, run:

```bash
rake test_all
```

## Developing and Testing with [Docker Compose](http://docs.docker.com/compose/)

To quickly try out _Thredded_ with the included dummy app, clone the source and
start the included docker-compose.yml file with:

```console
docker-compose build
docker-compose up -d
```

The above will build and run everything, daemonized, resulting in a running
instance on port 9292. Running `docker-compose logs` will let you know when
everything is up and running. Editing the source on your host machine will
be reflected in the running docker'ized application.

Note that when using [boot2docker](https://github.com/boot2docker/boot2docker)
on a Mac make sure you visit the boot2docker host ip at
`http://$(boot2docker ip):9292`.

After booting up the containers you can run the test suite with the following:

```console
docker-compose run web bundle exec rake
```

The docker container uses PostgreSQL.

[initializer]: https://github.com/thredded/thredded/blob/master/lib/generators/thredded/install/templates/initializer.rb
