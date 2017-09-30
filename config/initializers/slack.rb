Slack.configure do |config|
  config.token = Rails.application.secrets.slack_token
  fail 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end