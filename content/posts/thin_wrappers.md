---
title: "Thin wrappers"
date: 2023-01-15T17:39:56-05:00
draft: false
---

Third party dependencies are introduced in any project you work on. You can even think of a standard library
as a dependency which may have breaking api changes. In this blog post we will
explain the benefits of writing thin wrappers for any dependencies you might use throughout
your code base.

Example third-party dep (loosely based on the AWS sdk)

```go {style=gruvbox}
    type Client
    func New(o Options) *Client
    func (f *Client) ListServices(input *ListInput) *ListOutput
```

You use the dependency like:

```go {style=gruvbox}
    client := fooLib.New(&fooLib.Options{ApiKey: "123"})
    listOutput := client.ListServices(&fooLib.ListInput{
        name: "foo",
    })
```

At first glance you might ask why you would even bother writing a wrapper
for a client that doesn't require much code to begin with. You might even think that
given it's simply api, you wouldn't mind writing this out in several places of a
project that you needed to use it.

Now imagine your project starts rapdily growing and you begin using this client
in many more places. You also want to use another feature of this sdk, but you realize
that it is only supported in the latest version of the library. So you do as
any person would and update your dep/lock file to update the library to it's
latest version. You begin to run tests to confirm you haven't broken anything, and
immediately you're treated with errors about the `ListServices` function now
accepting a different type of parameter called `ListInputs` rather than the
previous `ListInput`.

You use a find/replace utility to replace all 30 occurences of said function.
However this is only the start, you're also using several other functions that have
had similar changes and some require additional inputs that can't be mass inserted
very easily. These types of changes begin to build up a large pull request that will
require the reviewers to look over dozens of files.

This burden is lessened if you write a small wrapper around this sdk that you then use
throughout your project.
This wrapper could look something like:

```go {style=gruvbox}
    // in your own repo, under //third-party/foo

    type Client struct{
        lib *fooLib.Client
    }

    func New(apiKey string) *Client{
      return &Client{
        lib: fooLib.New(&fooLib.Options{ApiKey: apiKey}),
      }
    }

    func (f Client) ListServices(name string) ListOutput {
        return f.lib.ListServices(&foolib.ListInput{name: name})
    }
```

Here, you're minimizing the interface of the `New` and `ListServices` functions
from the start, reducing the api knowledge a developer of your project is required
to posess in order to begin using it. Secondly, when that dependency is now updated,
you only need to update it's usage in one place:

```diff
    func (f Client) ListServices(name string) ListOutput {
-        return f.lib.ListServices(&ListInput{name: name})
+        return f.lib.ListServices(name)
```

And your pull pull request that once required dozens of files change would not only require
a single file to be changed.

These thin wrappers also help a lot when libraries are deprecated and superseded with
entirely different libraries. Those initial find/replace commands wouldn't work here
because now you might be working with a completely different api that uses a different
[creational pattern](https://en.wikipedia.org/wiki/Creational_pattern), and/or requires
several new imports.
Meanwhile our simple wrapper would continue to be updated in a single place, and the consumers
of your wrapper are untouched because our wrappers interface didn't need to change.

```diff
imports (
-  "github.com/fooCompany/fooLib"
+  "github.com/buzzCompany/buzzLib"
+  "github.com/buzzCompany/buzzLib/types"


    func New(apiKey string) *Client {
      return &Client{
-         lib: fooLib.New(&fooLib.Options{apiKey: apiKey})
+         lib: buzzLib.New(&types.Options{environment: "default", apiKey: apiKey}
      }
```
