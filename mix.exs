defmodule VersionCheck.Mixfile do
  use Mix.Project

  @version "0.1.1"

  def project do
    [app: :version_check,
     version: @version,
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     docs: docs(),
     deps: deps()]
  end

  def application do
    [applications: [:logger, :inets, :ssl],
     mod: {VersionCheck, []}]
  end

  defp deps do
    [{:earmark, ">= 0.0.0", only: :dev},
     {:ex_doc, "~> 0.13", only: :dev},
     {:credo, "~> 0.5", only: [:dev, :docs]},
     {:inch_ex, ">= 0.0.0", only: [:dev, :docs]}]
  end

  defp docs do
    [source_url: "https://github.com/gmtprime/version_check",
     source_ref: "v#{@version}",
     main: VersionCheck]
  end

  defp description do
    """
    Alerts about new versions of Elixir applications according to Hex.
    """
  end

  defp package do
    [maintainers: ["Alexander de Sousa"],
     licenses: ["MIT"],
     links: %{"Github" => "https://github.com/gmtprime/version_check"}]
  end
end
