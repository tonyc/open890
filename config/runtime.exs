import Config
require Logger

if config_env() == :prod do
  # just always make a new secret_key_base
  secret_key_base = :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64)

  config :open890, Open890Web.Endpoint,
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      transport_options: [socket_opts: [:inet6]]
    ],
    url: [host: "localhost", port: 4000],
    server: true,
    secret_key_base: secret_key_base
end

# Read HTTP basic auth config
with {:ok, file} <- File.read("config/config.toml"),
     {:ok, config} <- Toml.decode(file) do
  auth_config = config |> get_in(["http", "server", "auth"]) || []

  config :open890, Open890Web, auth: [
    enabled: auth_config["enabled"],
    username: auth_config["http_basic_username"],
    password: auth_config["http_basic_password"]
  ]
else
  _reason ->
    Logger.info("Could not read config/config.toml for http basic auth config")
end

