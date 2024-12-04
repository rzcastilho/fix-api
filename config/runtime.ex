import Config

config :fix_api,
  api_key: System.fetch_env!("API_KEY"),
  private_key: System.fetch_env!("PRIVATE_KEY"),
  public_key: System.fetch_env!("PUBLIC_KEY")
