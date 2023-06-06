defmodule Mix.Tasks.Changelog.Ci do

  use Mix.Task

  @impl true
  def run(_args) do
    Application.ensure_all_started(:dagger_ex)
    
    client = Dagger.connect!()

    client 
    |> Changelog.test()
    |> dbg()

    Dagger.close(client)
  end
end
