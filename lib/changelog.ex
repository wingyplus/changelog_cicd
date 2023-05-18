defmodule Changelog do
  @moduledoc """
  CI/CD port from https://github.com/thechangelog/changelog.com/tree/master/magefiles
  """

  @elixir_version "1.14.4"
  @otp_version "25.3"
  @ubuntu_version "jammy-20230126"
  @nodejs_version "18.15.0"
  @postgresql_version "14.1"

  @runtime_platform "linux/arm64"
  @runtime_platform_alt "linux-arm64"

  @doc """
  Running test.
  """
  def test() do
    client = Dagger.connect!()

    repo =
      client
      |> Dagger.Query.git("https://github.com/thechangelog/changelog.com.git", keep_git_dir: true)
      |> Dagger.GitRepository.branch("master")

    client
    |> container(@runtime_platform)
    |> Dagger.Container.pipeline("test")
    |> Changelog.Image.runtime(
      @elixir_version,
      @otp_version,
      @ubuntu_version,
      @nodejs_version,
      @runtime_platform_alt
    )
    |> with_app_src(repo)
    |> with_test_env()
    |> with_app_deps()
    |> with_postgresql(@postgresql_version, "changelog_test", client)
    |> with_test()
    |> Dagger.Container.exit_code()

    Dagger.disconnect(client)
  end

  def container(client, platform) do
    client
    |> Dagger.Query.container(platform: platform)
    |> Dagger.Container.with_env_variable("DEBIAN_FRONTEND", "noninteractive")
    |> Dagger.Container.with_env_variable("TERM", "xterm-256color")
  end

  def with_app_src(%Dagger.Container{} = container, %Dagger.GitRef{} = repository) do
    container
    |> Dagger.Container.with_directory("/app", Dagger.GitRef.tree(repository))
    |> Dagger.Container.with_workdir("/app")
  end

  def with_test_env(%Dagger.Container{} = container) do
    container
    |> Dagger.Container.with_env_variable("MIX_ENV", "test")
  end

  def with_app_deps(%Dagger.Container{} = container) do
    # TODO: implement cache.
    container
    |> Dagger.Container.with_exec(["mix", "deps.get"])
    |> Dagger.Container.with_exec(["mix", "deps.compile"])
    |> Dagger.Container.with_exec(["mix", "compile"])
  end

  def with_postgresql(%Dagger.Container{} = container, postgresql_version, db_name, client) do
    container_name = "#{db_name}_postgres"

    postgresql_container =
      client
      |> Dagger.Query.container()
      |> Dagger.Container.from("postgres:#{postgresql_version}")
      |> Dagger.Container.with_exposed_port(5432)
      |> Dagger.Container.with_env_variable("POSTGRES_USER", "postgres")
      |> Dagger.Container.with_env_variable("POSTGRES_PASSWORD", "postgres")
      |> Dagger.Container.with_env_variable("POSTGRES_DB", db_name)

    container
    |> Dagger.Container.with_service_binding(container_name, postgresql_container)
    |> Dagger.Container.with_env_variable("DB_HOST", container_name)
    |> Dagger.Container.with_env_variable("DB_NAME", db_name)
    |> Dagger.Container.with_env_variable("DB_USER", "postgres")
    |> Dagger.Container.with_env_variable("DB_PASSWORD", "postgres")
  end

  def with_test(%Dagger.Container{} = container) do
    container
    |> Dagger.Container.with_exec(["mix", "test"])
  end
end
