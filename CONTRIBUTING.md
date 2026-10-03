# Contributing

## Find something to work on

Issues labelled [`good first issue`](https://github.com/slovensko-digital/ops-portal/labels/good%20first%20issue) and [`help wanted`](https://github.com/slovensko-digital/ops-portal/labels/help%20wanted) are a good start. Comment on the issue before you start so work isn't duplicated.

## Report a bug or suggest a feature

Open an [issue](https://github.com/slovensko-digital/ops-portal/issues/new). For a bug, include steps to reproduce, what you expected and what happened.

Report security vulnerabilities privately through [Report a vulnerability](https://github.com/slovensko-digital/ops-portal/security/advisories/new), not as an issue.

## Make a change

1. Fork the repository and create a branch in your fork. Only maintainers can push here. In an existing clone, `gh repo fork --remote` adds your fork as `origin` and renames this repository to `upstream`.
2. Set up the app as described in the [README](README.md#local-setup).
3. Add or update tests at the level [docs/TESTING.md](docs/TESTING.md) describes.
4. Run `bin/ci` and make sure it passes.

## Open a pull request

Open it from your fork against `main`, link the issue (`Closes #123`) and fill in the template's sections. In Claude Code, `/prepare-pr-for-review` writes the description from `.github/pull_request_template.md`.

A maintainer may need to approve the CI run on your first pull request.
