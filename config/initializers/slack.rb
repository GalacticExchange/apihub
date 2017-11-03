require 'vault'

Slack.configure do |config|
  slack_token =  Vault.logical.read("secret/slack").data[:token]
  config.token = slack_token
  fail 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end