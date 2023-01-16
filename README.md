Workflow:

1. Switch to `development` branch and add a new post

```bash

    hugo new posts/thin_wrappers.md
```

1. Run development server to confirm how it looks

```bash

    hugo server -D
```

1. When ready, set `draft` to `false` on the post
1. Run `deploy.sh` which will build the static files and bring to the master branch
1. Commit and push the changes to the master branch
