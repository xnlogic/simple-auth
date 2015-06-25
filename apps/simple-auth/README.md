TODO
================

- Where should api config + db be stored? (/opt/xn_apps?)
- why did we have confirmed/unconfirmed status in users?
- creating users
  - select client
  - default client
  - wtf is up with name field
- compatibility with previous auth routes
- ensure json sign in works
- user admin
  - admin capabilities based on membership in configured matching group in API
  - copy over the group management UI
  - render user list
- what to show non-admin users?

Users are replicated to the API as soon as they are created.
x delete users in API when they are deleted? (no)
- delete user tokens when user is deleted

Future:
- many clients per user?

Auth
================

This application was generated with the [rails_apps_composer](https://github.com/RailsApps/rails_apps_composer) gem
provided by the [RailsApps Project](http://railsapps.github.io/).

Rails Composer is open source and supported by subscribers. Please join RailsApps to support development of Rails Composer.

Problems? Issues?
-----------

Need help? Ask on Stack Overflow with the tag 'railsapps.'

Your application contains diagnostics in the README file. Please provide a copy of the README file when reporting any issues.

If the application doesn't work as expected, please [report an issue](https://github.com/RailsApps/rails_apps_composer/issues)
and include the diagnostics.

Ruby on Rails
-------------

This application requires:

- Ruby 2.2.2
- Rails 4.2.1

Learn more about [Installing Rails](http://railsapps.github.io/installing-rails.html).

Getting Started
---------------

Documentation and Support
-------------------------

Issues
-------------

Similar Projects
----------------

Contributing
------------

Credits
-------

License
-------
