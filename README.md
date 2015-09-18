XN Logic Simple Authentication Server
================

The XN framework provides powerful authorization tools, but relies on external authentication providers for
maximum flexibility in enterprise environments. This auth server is a very bare-bones Rails application based
on Devise that may be used to provide authentication in case there is no pre-existing provider available.

Installation
================

In your project root directory:

```bash
git remote add auth https://github.com/xnlogic/simple-auth.git
git fetch auth
git merge auth master
```

You will need to add the auth container to your docker-compose.yml as well.

Development:
```yaml
auth:
  build: apps/simple-auth
  links:
    - api
  volumes_from:
    - data
  volumes:
    - ./apps/simple-auth:/app
  environment:
    XN_ENV: development
    RAILS_ENV: development
```

Production:
```yaml
prodauth:
  image: lightmesh/simple-auth
  links:
    - prodapi
  volumes_from:
    - data
  environment:
    XN_ENV: production
    RAILS_ENV: production
    ADMIN_NAME: "Configure Me"
    ADMIN_EMAIL: "admin@example.com"
    ADMIN_PASSWORD: "..........."
    DOMAIN_NAME: "example.com"
    # Use the following command to generate the secret key base:
    # docker-compose run --rm prodauth rake token
    SECRET_KEY_BASE: "0000000000000000000000000000000000000000000000000000000000000000000000000000000000"
```

Don't forget to set the secret key and configure your email settings!

```bash
docker-compose run --rm prodauth rake token
```

License
-------

Copyright 2015 XN Logic

TODO
================

Creating users
- select client
- default client

Future:
- many clients per user?

