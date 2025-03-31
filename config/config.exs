# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :draft_guru,
  ecto_repos: [DraftGuru.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :draft_guru, DraftGuruWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: DraftGuruWeb.ErrorHTML, json: DraftGuruWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: DraftGuru.PubSub,
  live_view: [signing_salt: "MQyB2pus"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :draft_guru, DraftGuru.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  draft_guru: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  draft_guru: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :draft_guru, DraftGuru.NBADotComScraper,
  base_url: "https://www.nba.com/stats/draft/",
  seasons: ["2024-25",
            "2023-24",
            "2022-23",
            "2021-22",
            "2020-21",
            "2019-20",
            "2018-19",
            "2017-18",
            "2016-17",
            "2015-16",
            "2014-15",
            "2013-14",
            "2012-13",
            "2011-12",
            "2010-11",
            "2009-10",
            "2008-09",
            "2007-08",
            "2006-07",
            "2005-06",
            "2004-05",
            "2003-04",
            "2002-03",
            "2001-02"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :wallaby,
  driver: Wallaby.Chrome,
  chrome: [
    headless: true
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# for basic authentication
config :draft_guru, :basic_auth,
  username: "admin$%*",
  password: "453kc8d%8dk3k!"

config :waffle,
  storage: Waffle.Storage.Local,
  uploader: DraftGuru.ImageUploader

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
