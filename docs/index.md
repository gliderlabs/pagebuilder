# Pagebuilder

[![CircleCI](https://img.shields.io/circleci/project/gliderlabs/pagebuilder.svg)](https://circleci.com/gh/gliderlabs/pagebuilder)

This is the tool Glider Labs uses to generate and deploy project documentation.

* Built around [MkDocs](http://www.mkdocs.org/) for generating sites based on Markdown
* Deploys to Github Pages under sub-directories for versioning
* Automation and UI to keep and expose docs for other branches and old releases
* Centralizes theming and layout across all projects
* Packaged as a lightweight Docker container usable from anywhere
* Drop-in command to use from CircleCI without messy scripts

Make documentation for your project following the instructions for [MkDocs](http://www.mkdocs.org/). Namely,
creating a `docs` folder for Markdown and a `mkdocs.yml` file at the project root.

## Configuration

The only extra configuration Pagebuilder expects in `mkdocs.yml` is:

```yaml
theme_dir: /pagebuilder/theme
```
You should also set `site_url` to the URL of the base of the deployment for the
version dropdown to work correctly.

## Previewing

You can preview your docs with Pagebuilder in Docker. Running from project root:

```bash
$ docker run --rm -p 8000:8000 -v $PWD:/work gliderlabs/pagebuilder mkdocs serve
```

## CircleCI

Add a deployment command to your `circle.yml` to build and publish the docs
with every build. Here is an example:

```yaml
deployment:
  master:
    branch: master
    commands:
      - eval $(docker run gliderlabs/pagebuilder circleci-cmd)
```

This is a convenience wrapper that automates all the extra Docker flags needed to
allow pushing the built site to `gh-pages` branch of the repo.

You need to run this command for every branch you want to build docs for. If
you want to use a branch other than `master` to be used for the `latest` docs,
specify it with `MASTER` environment variable. Here is how you would tell it to
use `release` for latest. It will still make a `release` directory on Github Pages,
but the `latest` directory will be a copy of it.

```yaml
deployment:
  master:
    branch: master
    commands:
      - eval $(docker run -e MASTER=release gliderlabs/pagebuilder circleci-cmd)
```
