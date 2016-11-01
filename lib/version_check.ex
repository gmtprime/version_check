defmodule VersionCheck do
  @moduledoc """
  This module defines an application and a macro to generate alerts about new
  versions of applications in Hex. The messages are shown using `Logger` as a
  warning.

  When starting an app using the function or the `VersionCheck` application you
  should see something like:

      % iex -S mix
      Erlang/OTP 19 [erts-8.1] [source-4cc2ce3] [64-bit] [smp:8:8]
      [async-threads:10] [hipe] [kernel-poll:false]

      Interactive Elixir (1.3.2) - press Ctrl+C to exit (type h() ENTER for help)

      17:30:42.454 [warn] A new yggdrasil version is available (2.0.8 > 2.0.7)
      17:30:42.454 [debug] Using the latest version of :version_check (0.1.0)
      iex(1)>

  ## Using VersionCheck

  When adding `use VersionCheck` to a module, the module adds the public
  function `check_version/0`. If it is called from inside the `start/2`
  function of the `Application` behaviour it'll check the current application
  version against `hex.pm` before it starts i.e:

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

  ## VersionCheck App

  It is also possible to add `VersionCheck` to your required applications in
  your `mix.exs` file i.e:

      def application do
        [applications: [:version_check]]
      end

  This app will check the version of every application started. That's why it
  should be the last application in the list.
  """
  use Application
  require Logger

  @doc false
  defmacro __using__(options) do
    app_name = Keyword.get(options, :application)
    quote do
      @doc false
      def check_version, do: VersionCheck.check_version(unquote(app_name))
    end
  end

  @default_url "https://hex.pm/api/packages/"
  @hex_url Application.get_env(:version_check, :hex_url, @default_url)

  @doc false
  def get_version([], _) do
    Mix.Project.config[:version]
  end
  def get_version([{app_name, _, version} | _], app_name)
      when is_list(version) do
    version |> List.to_string()
  end
  def get_version([_ | xs], app_name), do: get_version(xs, app_name)

  def check_version(app_name) do
    version = :application.which_applications() |> get_version(app_name)
    check_version(app_name, version)
  end

  @doc false
  # Checks version for an app.
  def check_version(_, nil), do: :ok
  def check_version(app_name, current)
    when is_atom(app_name) and not is_nil(app_name) do
    all_versions = fetch_all_hex_versions(app_name, current)

    case should_update?(all_versions, current) do
      :yes ->
        latest = latest_version(all_versions, current)
        relation = "#{latest} > #{current}"
        log = "A new #{app_name} version is available (#{relation})"
        Logger.warn(log)
      :no ->
        log = "Using the lastest version of #{app_name} (#{current})"
        Logger.debug(log)
      :not_found ->
        :ok
    end
  end
  def check_version(_, _) do
    log = "No application defined for VersionCheck"
    Logger.error(log)
  end

  @doc false
  # Fetches all Hex versions.
  def fetch_all_hex_versions(package_name, current)
      when is_atom(package_name) do
    package_name
    |> package_name_to_hex_url()
    |> fetch(package_name, current)
    |> hex_versions()
  end

  @doc false
  # Package name to Hex URL.
  def package_name_to_hex_url(package_name) when is_atom(package_name) do
    package_name
    |> Atom.to_string()
    |> (fn app -> @hex_url <> app end).()
  end

  @doc false
  # Fetches the Hex versions from an URL.
  def fetch(url, package_name, current) do
    req = {
      String.to_charlist(url),
      [{'User-Agent', user_agent(package_name, current)},
        {'Accept', 'application/vnd.hex+erlang'}
      ]
    }

    response = :httpc.request(:get, req, [], [])
    response |> convert_response_body()
  end

  @doc false
  # User agent for the request.
  def user_agent(package_name, version) do
    name =
      package_name
      |> Atom.to_string()
      |> String.split("_")
      |> Enum.map(&String.capitalize/1)
      |> List.to_string()
    '#{name}/#{version} (Elixir/#{System.version}) (OTP/#{System.otp_release})'
  end

  @doc false
  # Converts response body to erlang term.
  def convert_response_body({:ok, {_status, _headers, body}}) do
    body
    |> IO.iodata_to_binary()
    |> :erlang.binary_to_term()
  end
  def convert_response_body(_), do: nil

  @doc false
  # Gets all Hex versions.
  def hex_versions(%{"releases" => releases}) do
    releases |> Enum.map(&(&1["version"]))
  end
  def hex_versions(_), do: []

  @doc false
  # Whether the app should be updated or not.
  def should_update?([], _), do: :not_found
  def should_update?(all_versions, current) do
    latest = latest_version(all_versions, current)
    if Hex.Version.compare(current, latest) == :lt, do: :yes, else: :no
  end

  @doc false
  # Gets the latest version.
  def latest_version(all_versions, default) do
    including_pre_versions? = pre_version?(default)
    latest = highest_version(all_versions, including_pre_versions?)
    latest || default
  end

  @doc false
  # Whether it allows previous versions or not.
  def pre_version?(version) do
    {:ok, version} = Hex.Version.parse(version)
    version.pre != []
  end

  @doc false
  # Gets the highest version.
  def highest_version(versions, including_pre_versions?) do
    if including_pre_versions? do
      versions |> List.last
    else
      versions |> Enum.reject(&pre_version?/1) |> List.last
    end
  end

  ###############
  # App callback.

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    checks = fn ->
      for {app, _, version} <- Application.started_applications() do
        check_version(app, version)
      end
      check_version(:version_check)
    end

    children = [
      worker(Task, [checks], restart: :transient)
    ]

    opts = [strategy: :one_for_one, name: VersionCheck]
    Supervisor.start_link(children, opts)
  end
end
