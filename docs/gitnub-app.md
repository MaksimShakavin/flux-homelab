## Setting up github app for a new repository

1. Create github app following the [guideline](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app)
2. Copy app ID and save it to a `BOT_APP_ID` repository secret and to a `ACTION_RUNNER_CONTROLLER_GITHUB_APP_ID` property of
an `actions-runner-controller` 1Password secret.
3. Generate a new app private key and add it to a `BOT_APP_PRIVATE_KEY` repository secret and to a `ACTION_RUNNER_CONTROLLER_GITHUB_PRIVATE_KEY`
property of an `actions-runner-controller` 1Password secret in the format
```
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----

```
