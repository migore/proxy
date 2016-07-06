# Proxy

A small proxy that I hakcked that caches responses. The goal is to be used for development so that you can edit responses as needed.

## How to use it

Change `config/config.exs` and add the base url for the site that you want.

Run it with:

    mix deps.get
    mix serve

Set the base url of your application to your machine IP, port 4001. Example for localhost:

    http://localhost:4001/

The file with the response of each request will be in a directory called `cache` in the root of the project.

## Disclaimer

Even though it's not a fork of [José Valim's proxy](https://github.com/josevalim/proxy), this is based on that repository and there is code from that repository in this project.
