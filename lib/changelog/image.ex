defmodule Changelog.Image do
  @moduledoc false

  def elixir_image_ref(elixir_version, otp_version, ubuntu_version) do
    "hexpm/elixir:#{elixir_version}-erlang-#{otp_version}-ubuntu-#{ubuntu_version}"
  end

  def elixir(%Dagger.Container{} = container, elixir_version, otp_version, ubuntu_version) do
    container
    |> Dagger.Container.from(elixir_image_ref(elixir_version, otp_version, ubuntu_version))
    |> Dagger.Container.with_exec(["mix", "--version"])
    |> Dagger.Container.with_exec(["mix", "local.rebar", "--force"])
    |> Dagger.Container.with_exec(["mix", "local.hex", "--force"])
  end

  def with_apt_packages(%Dagger.Container{} = container) do
    container
    |> Dagger.Container.with_exec(["apt-get", "update"])
  end

  def with_git(%Dagger.Container{} = container) do
    container
    |> Dagger.Container.with_exec(["apt-get", "install", "--yes", "git-core"])
    |> Dagger.Container.with_exec(["git", "--version"])
  end

  def with_image_magick(%Dagger.Container{} = container) do
    container
    |> Dagger.Container.with_exec(["apt-get", "install", "--yes", "imagemagick"])
    |> Dagger.Container.with_exec(["convert", "--version"])
  end

  def with_cmark_prerequisites(%Dagger.Container{} = container) do
    container
    |> Dagger.Container.with_exec(["apt-get", "install", "--yes", "build-essential"])
    |> Dagger.Container.with_exec(["gcc", "--version"])
  end

  def with_inotify_tools(%Dagger.Container{} = container) do
    container
    |> Dagger.Container.with_exec(["apt-get", "install", "--yes", "inotify-tools"])
    |> Dagger.Container.with_exec(["which", "inotifywatch"])
  end

  def with_postgresql_client(%Dagger.Container{} = container) do
    container
    |> Dagger.Container.with_exec(["apt-get", "install", "--yes", "postgresql-client"])
    |> Dagger.Container.with_exec(["psql", "--version"])
  end

  def with_curl(%Dagger.Container{} = container) do
    container
    |> Dagger.Container.with_exec(["apt-get", "install", "--yes", "curl"])
    |> Dagger.Container.with_exec(["curl", "--version"])
  end

  def with_xz(%Dagger.Container{} = container) do
    container
    |> Dagger.Container.with_exec(["apt-get", "install", "--yes", "xz-utils"])
    |> Dagger.Container.with_exec(["xz", "--version"])
  end

  def with_nodejs(%Dagger.Container{} = container, nodejs_version, runtime_platform) do
    nodejs_version_and_platform = "node-v#{nodejs_version}-#{runtime_platform}"

    container
    |> with_curl()
    |> with_xz()
    |> Dagger.Container.with_exec([
      "curl",
      "--silent",
      "--fail",
      "--location",
      "--output",
      "/opt/#{nodejs_version_and_platform}.tar.xz",
      "https://nodejs.org/dist/v#{nodejs_version}/#{nodejs_version_and_platform}.tar.xz"
    ])
    |> Dagger.Container.with_exec([
      "tar",
      "-xJvf",
      "/opt/#{nodejs_version_and_platform}.tar.xz",
      "-C",
      "/opt"
    ])
    |> Dagger.Container.with_env_variable(
      "PATH",
      "/opt/#{nodejs_version_and_platform}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    )
    |> Dagger.Container.with_exec(["node", "--version"])
    |> Dagger.Container.with_exec(["npm", "--version"])
    |> Dagger.Container.with_exec(["rm", "/opt/#{nodejs_version_and_platform}.tar.xz"])
  end

  def with_yarn(%Dagger.Container{} = container) do
    container
    |> Dagger.Container.with_exec(["npm", "install", "--global", "yarn"])
    |> Dagger.Container.with_exec(["yarn", "--version"])
  end

  def runtime(
        %Dagger.Container{} = container,
        elixir_version,
        otp_version,
        ubuntu_version,
        nodejs_version,
        runtime_platform_alt
      ) do
    container
    |> elixir(elixir_version, otp_version, ubuntu_version)
    |> with_apt_packages()
    |> with_git()
    |> with_image_magick()
    |> with_cmark_prerequisites()
    |> with_inotify_tools()
    |> with_postgresql_client()
    |> with_nodejs(nodejs_version, runtime_platform_alt)
    |> with_yarn()
  end
end
