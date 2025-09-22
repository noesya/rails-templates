# SMS via Brevo

## Prerequisites

An app configured with Devise and two-factor authentication.

## Setup

- Add the gem with `bundle add brevo`
- Create an API key and add it to environment variables with the name `BREVO_API_KEY`
- Add the initializer `config/initializers/brevo.rb`
  ```rb
  # Load the gem
  require 'brevo'

  # Setup authorization
  Brevo.configure do |config|
    config.api_key['api-key'] = ENV['BREVO_API_KEY']
    config.api_key['partner-key'] = ENV['BREVO_API_KEY']
  end

  api_instance = Brevo::AccountApi.new

  begin
    # Get your account information, plan and credits details
    result = api_instance.get_account
  rescue Brevo::ApiError => e
    puts "Exception when calling AccountApi->get_account: #{e}"
  end
  ```

## SMS Ruby service

Boilerplate to add in `app/services/brevo/sms_service.rb`

```rb
module Brevo
  class SmsService
    DEFAULT_SENDER_NAME = 'Sender Name'.freeze

    def self.send_mfa_code(user, code)
      duration =  ActiveSupport::Duration.build(Rails.application.config.devise.direct_otp_valid_for).inspect
      message = "#{code} is your authentication code (valid for #{duration})"
      self.send_message(user, message)
    end

    private

    def self.send_message(user, message)
      api_instance = SibApiV3Sdk::TransactionalSMSApi.new
      send_transac_sms = SibApiV3Sdk::SendTransacSms.new(
        sender: DEFAULT_SENDER_NAME,
        recipient: user.mobile_phone,
        content: message
      )

      begin
        # Send SMS message to a mobile number
        result = api_instance.send_transac_sms(send_transac_sms)
        p result
      rescue SibApiV3Sdk::ApiError => e
        puts "Exception when calling TransactionalSMSApi->send_transac_sms: #{e}"
      end
    end
  end
end
```
