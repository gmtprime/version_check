# VersionCheck

[![Build Status](https://travis-ci.org/gmtprime/version_check.svg?branch=master)](https://travis-ci.org/gmtprime/version_check) [![Hex pm](http://img.shields.io/hexpm/v/version_check.svg?style=flat)](https://hex.pm/packages/version_check) [![hex.pm downloads](https://img.shields.io/hexpm/dt/version_check.svg?style=flat)](https://hex.pm/packages/version_check) [![Deps Status](https://beta.hexfaktor.org/badge/all/github/gmtprime/version_check.svg)](https://beta.hexfaktor.org/github/gmtprime/version_check) [![Inline docs](http://inch-ci.org/github/gmtprime/version_check.svg?branch=master)](http://inch-ci.org/github/gmtprime/version_check)

This module defines an application and a macro to generate alerts about new
versions of applications in Hex. The messages are shown using `Logger` as a
warning.

## Using VersionCheck

When adding `use VersionCheck` to a module, the module adds the public
function `check_version/0`. If it is called from inside the `start/2`
function of the `Application` behaviour it'll check the current application
version against `hex.pm` before it starts i.e:

```elixir
defmodule MyApp do
  use Application
  use VersionCheck, application: :my_app

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    check_version()

    children = [
      (...)
    ]
        
    opts = (...)

    Supervisor.start_link(children, opts)
  end
end
```

## VersionCheck App

It is also possible to add `VersionCheck` to your required applications in
your `mix.exs` file i.e:

```elixir
def application do
  [applications: [:version_check]]
end
```

This app will check the version of every application started. That's why it
should be the last application in the list.


## Installation

Just add it to your deps:


```elixir
def deps do
  [{:version_check, "~> 0.1"}]
end
```

To use it as an application, ensure it is started before your application and
after all the applications required by your application:

```elixir
def application do
  [applications: [(...), :version_check]]
end
```

## Credits

`VersionCheck` owns its existence to the study and "code borrowing" from
`Credo`'s function that checks for updates.

## Author

Alexander de Sousa.

## License

`Yggdrasil` is released under the MIT License. See the LICENSE file for further
details.
