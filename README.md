# hb-oauth2-diy


This is a fork of Honeybadger's OAuth2 source code for a Sinatra client consumer application using [oauth2](https://github.com/oauth-xx/oauth2/blob/v1.4.4/README.md).

It includes _only_ the client implementation, as we are going to use [Shopify's Identity provider](https://accounts.shopify.com) as the server.

Make sure to have Ruby 2.7 (or greater) installed in your machine.


### Create a local SSL Certificate

See [this post](https://medium.com/@matayoshi.mariano/how-to-add-ssl-to-your-localhost-with-puma-37a66a649f29
) for how to create the Cert on your Mac. Ignore the parts about Puma,

Install `mkcert`

```
> brew install mkcert
> brew install nss # if you use Firefox
```

Make a local cert

```bash
> mkcert localhost
Created a new local CA 💥
Note: the local CA is not installed in the system trust store.
Note: the local CA is not installed in the Firefox trust store.
Run "mkcert -install" for certificates to be trusted automatically ⚠️

Created a new certificate valid for the following names 📜
 - "localhost"

The certificate is at "./localhost.pem" and the key at "./localhost-key.pem" ✅

It will expire on 11 April 2023 🗓
```

Follow the instructions in the blog post to add the cert to Keychain Access.App

### The consumer



In the root folder, run

```
bundle install
```

The `CLIENT_ID` and `CLIENT_SECRET` are not supplied in the code. You must pass them in as environment variables.

Then, run the client app by issuing the following command:
```
CLIENT_ID=<id> CLIENT_SECRET=<secret> bundle exec ruby app.rb
```

You app will be available at https://localhost:8888/.

Navigate to https://localhost:8888/auth/test to begin the flow
