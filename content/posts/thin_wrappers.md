---
title: "Thin wrappers"
date: 2023-01-15T17:39:56-05:00
draft: false
---

Third party dependencies are introduced in any project you work on. You can even
think of a standard library as a dependency which may have breaking API changes.
In this blog post we will explain the benefits of writing thin wrappers for
dependencies you might use throughout your code base.

Example third-party dependency (loosely based on the AWS sdk)

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
for a client that doesn't require much code to begin with. Given it's simply API,
you wouldn't mind writing this out in several places of a project.

Now imagine your project starts rapidly growing and you begin using this client
in many more places. You also want to use a new feature of this library, but
that requires you to update to the latest version of the library.
You make the appropriate changes to update the library to it's latest version. Upon
running tests to catch breaking changes, you're treated with errors about the
`ListServices` function now accepting a different type of parameter called `ListInputs`
rather than the previous `ListInput`.

You use a find/replace utility to replace all 30 occurrences of said function.
However this is only the start. You're also using several other functions that have
had similar changes and some require additional inputs that can't be mass inserted
very easily. These types of changes begin to build up a large pull request that will
require the reviewers to look over dozens of files.

This burden is lessened if you write a small wrapper around this library that you
then use throughout your project.

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

By creating this wrapper, you are doing several things for consumers of the
library:

1. You're minimizing the interface of the constructor and instance functions. This
   will make it easier to onboard new developers to this library who now no longer
   need to reference the original libraries API docs.
2. You can alter the interface to follow a pattern you and other developers
   are already using everywhere else.
3. You are narrowing the import and usage of the library to only this wrapper. Rather
   than updating the dependency in all 30+ locations that it's used, you only need to
   update your wrapper like:

```diff
    func (f Client) ListServices(name string) ListOutput {
-        return f.lib.ListServices(&ListInput{name: name})
+        return f.lib.ListServices(name)
```

And now your pull request that once required dozens of file changes, only requires
a single file to be changed.

These thin wrappers also help a lot when libraries are deprecated and superseded with
entirely different libraries. Those initial find/replace commands wouldn't work here
because now you might be working with a completely different API that uses a different
[creational patterns](https://en.wikipedia.org/wiki/Creational_pattern), and/or requires
several new imports. Meanwhile our simple wrapper would continue to be updated in a
single place, and the consumers of your wrapper are untouched because our wrappers
interface didn't need to change.

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

Writing these wrappers isn't always necessary and can also be overused. You'll
want to carefully chose when a library would benefit from a thin wrapper like this.
A couple questions that you can ask yourself before committing to a wrapper include:

1. Is the library going to be heavily used within the project?
1. Is the library relatively new and often undergo rewrites?
1. Is the library an abstraction for constantly evolving lower level technology?
1. Does the library introduce breaking API changes frequently?
1. Does the library have superfluous options, most of which you don't expect to use?
