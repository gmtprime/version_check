defmodule VersionCheckTest do
  use ExUnit.Case, async: true
  alias VersionCheck, as: VC

  defmodule VersionCheckTest do
    use VersionCheck, application: :yggdrasil
  end

  test "package_name_to_hex_url/1" do
    hex_url = VC.package_name_to_hex_url(:version_check)
    expected = "https://hex.pm/api/packages/version_check"
    assert hex_url == expected
  end

  test "user_agent/1" do
    user_agent = VC.user_agent(:version_check)
    expected = 'VersionCheck/0.1.0 (Elixir/#{System.version}) (OTP/#{System.otp_release})'
    assert user_agent == expected
  end
end
