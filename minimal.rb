# .ruby-version
########################################
gsub_file ".ruby-version", "ruby-", ""

# Gemfile
########################################
inject_into_file "Gemfile", before: "group :development, :test do" do
  <<~RUBY
    gem "activestorage-scaleway-service", "~> 1.1"
    gem "annotaterb", "~> 4.16"
    gem "autoprefixer-rails", "~> 10.4"
    gem "bootstrap", "~> 5.3"
    gem "bootstrap5-kaminari-views", "~> 0.0"
    gem "breadcrumbs_on_rails", "~> 4.1"
    gem "good_job", "~> 4.11"
    gem "kamifusen", "~> 1.12"
    gem "kaminari", "~> 1.2"
    gem "rails-i18n", "~> 8.0"
    gem "sassc-rails", "~> 2.1"
    gem "simple_form", "~> 5.3"
    gem "simple_form_bs5_file_input", "~> 0.1"
    gem "sprockets-rails", "~> 3.5"
    gem "terser", "~> 1.2"

  RUBY
end
uncomment_lines 'Gemfile', /image_processing/
gsub_file "Gemfile", "  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem\n", ""
gsub_file "Gemfile", "  gem \"debug\", platforms: %i[ mri windows ], require: \"debug/prelude\"\n", ""
inject_into_file "Gemfile", after: "group :development, :test do\n" do
  ["byebug", "dotenv-rails"].map { |gem|
    "  gem \"#{gem}\"\n"
  }.join
end

# Assets
########################################
initializer "assets.rb", <<~RUBY
  # Be sure to restart your server when you modify this file.

  # Version of your assets, change this if you want to expire all your assets.
  Rails.application.config.assets.version = "1.0"

  # Add additional assets to the asset load path.
  # Rails.application.config.assets.paths << Rails.root.join('node_modules')

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in the app/assets
  # folder are already added.
  # Rails.application.config.assets.precompile += %w( admin.js admin.css )

  Rails.application.config.assets.export_concurrent = false
RUBY
file "app/assets/config/manifest.js", <<~JS
  //= link_tree ../fonts
  //= link_tree ../images
  //= link_directory ../javascripts .js
  //= link_directory ../stylesheets .css
JS
remove_file "app/assets/stylesheets/application.css"
file "app/assets/fonts/.keep"
file "app/assets/javascripts/application.js", <<~JS
  //= require popper
  //= require bootstrap-sprockets
  //= require activestorage
  //= require rails-ujs
  //= require simple_form_bs5_file_input
JS

file "app/assets/stylesheets/application.sass", <<~SASS
  @import 'bootstrap'
  @import 'simple_form_bs5_file_input'
SASS

# Layout
########################################
inject_into_file "app/views/layouts/application.html.erb", after: "<%= yield %>\n" do
  "    <%= javascript_include_tag \"application\" %>\n"
end

# README
########################################
markdown_file_content = <<~MARKDOWN
  # README

  Application Rails générée avec [noesya/rails-templates](https://github.com/noesya/rails-templates), créé par l'équipe [noesya](https://www.noesya.coop).
MARKDOWN
file "README.md", markdown_file_content, force: true

# General Config
########################################
inject_into_file "config/application.rb", after: "require \"action_cable/engine\"\n" do
  "require \"sprockets/railtie\"\n"
end
inject_into_file "config/application.rb", after: "config.eager_load_paths << Rails.root.join(\"extras\")\n" do
  <<-RUBY

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
        address: "smtp-relay.brevo.com",
        port: 587,
        user_name: ENV['SMTP_USER'],
        password: ENV['SMTP_PASSWORD'],
        authentication: :plain
    }

    # TODO Remove when kamifusen is compatible with Vips
    config.active_storage.variant_processor = :mini_magick
    # Need for +repage, because of https://github.com/rails/rails/commit/b2ab8dd3a4a184f3115e72b55c237c7b66405bd9
    config.active_storage.supported_image_processing_methods = ["+"]
    config.active_storage.service_urls_expire_in = 1.hour

    config.generators do |generate|
      generate.assets false
      generate.helper false
      generate.system_tests = nil
      generate.orm :active_record, primary_key_type: :uuid
    end

    config.sass.preferred_syntax = :sass
  RUBY
end
uncomment_lines "config/application.rb", /config\.time_zone/
gsub_file "config/application.rb", "Central Time (US & Canada)", "Europe/Paris"

# Development Config
########################################
inject_into_file "config/environments/development.rb", before: /^end$/ do
  <<-RUBY

  config.assets.debug = true
  config.assets.quiet = true
  config.active_job.queue_adapter = :good_job

  RUBY
end

# Production Config
########################################
inject_into_file "config/environments/production.rb", before: /^end$/ do
  <<-RUBY

  config.assets.js_compressor = :terser
  config.assets.compile = false
  config.active_job.queue_adapter = :good_job

  RUBY
end
gsub_file "config/environments/production.rb", "\"example.com\"", "ENV['SITE_URL']"

# ApplicationController
########################################
app_controller_content = <<~RUBY
  class ApplicationController < ActionController::Base
    include WithErrors
  end
RUBY
file "app/controllers/application_controller.rb", app_controller_content, force: true
app_controller_with_errors_content = <<~RUBY
  module ApplicationController::WithErrors
    extend ActiveSupport::Concern

    included do
      rescue_from ActionController::RoutingError do |exception|
        render_not_found
      end

      rescue_from ActionController::UnknownFormat do |exception|
        render_not_found
      end

      rescue_from ActiveRecord::RecordNotFound do |exception|
        render_not_found
      end

      rescue_from ActiveStorage::FileNotFoundError do |exception|
        render_not_found
      end

      def raise_404_unless(condition)
        raise ActionController::RoutingError.new('Not Found') unless condition
      end

      def handle_unverified_request
        redirect_back(fallback_location: root_path, alert: t('inactivity_alert'))
      end

      def render_not_found
        render file: Rails.root.join('public/404.html'), formats: [:html], status: 404, layout: false
      end
    end
  end
RUBY
file "app/controllers/application_controller/with_errors.rb", app_controller_with_errors_content, force: true

# Active Storage configuration
########################################
initializer "active_storage.rb", <<~RUBY
Rails.application.config.to_prepare do
  ActiveStorage::Engine.config.active_storage.content_types_to_serve_as_binary.delete('image/svg+xml')

  # Override ActiveStorage::Filename#sanitized to remove accents and all special chars
  # Base method: https://github.com/rails/rails/blob/v7.0.3/activestorage/app/models/active_storage/filename.rb#L57
  ActiveStorage::Filename.class_eval do
    def sanitized
      base_filename = base.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "�")
                          .strip
                          .tr("\\u{202E}%$|:;/\\t\\r\\n\\\\", "-")
                          .parameterize(preserve_case: true)
      [base_filename, extension_with_delimiter].join('')
    end
  end
end
RUBY
storage_yml_content = <<~YAML
  test:
    service: Disk
    root: <%= Rails.root.join("tmp/storage") %>

  local:
    service: Disk
    root: <%= Rails.root.join("storage") %>

  scaleway:
    service: Scaleway
    access_key_id: <%= ENV['SCALEWAY_OS_ACCESS_KEY_ID'] %>
    secret_access_key: <%= ENV['SCALEWAY_OS_SECRET_ACCESS_KEY'] %>
    region: <%= ENV['SCALEWAY_OS_REGION'] %>
    bucket: <%= ENV['SCALEWAY_OS_BUCKET'] %>
    endpoint: <%= ENV['SCALEWAY_OS_ENDPOINT'] %>
    public: true
    upload:
      cache_control: 'public, max-age=31536000'
YAML
file "config/storage.yml", storage_yml_content, force: true

# Action Mailer configuration
########################################
gsub_file "app/mailers/application_mailer.rb",
          "default from: \"from@example.com\"",
          "default from: \"\#{ENV[\'MAIL_FROM_NAME']} <\#{ENV['MAIL_FROM_MAIL']}>\""
inject_into_file "app/mailers/application_mailer.rb", after: "layout \"mailer\"\n" do
  <<-RUBY

  def default_url_options
    {
      host: ENV['SITE_URL'],
      port: Rails.env.development? ? 3000 : nil
    }
  end
  RUBY
end

# Gitignore
########################################
append_file ".gitignore", <<~TXT

  # Ignore env file containing credentials.
  /.env
  !/.env.sample

  # Ignore Mac file system files
  .DS_Store

  # Ignore byebug history
  .byebug_history

  # Ignore node_modules just in case
  /node_modules
TXT

# Dotenv
########################################
file ".env.sample", <<~TXT
  APPLICATION_ENV=development

  MAIL_FROM_MAIL=
  MAIL_FROM_NAME=

  SCALEWAY_OS_ACCESS_KEY_ID=
  SCALEWAY_OS_BUCKET=
  SCALEWAY_OS_ENDPOINT=https://s3.fr-par.scw.cloud
  SCALEWAY_OS_REGION=fr-par

  SITE_URL=http://localhost:3000

  SMTP_PASSWORD=
  SMTP_USER=

  # Not needed in development, but mandatory in production
  # JEMALLOC_ENABLED=true
  # LD_LIBRARY_PATH='$LD_LIBRARY_PATH:/app/.apt/usr/lib/x86_64-linux-gnu/pulseaudio:/app/.apt/usr/lib/x86_64-linux-gnu/blas:/app/.apt/usr/lib/x86_64-linux-gnu/lapack'
  # WEB_CONCURRENCY=0
TXT
run "cp .env.sample .env"

# Scalingo
########################################
file ".buildpacks", <<~TXT
  https://github.com/Scalingo/jemalloc-buildpack.git
  https://github.com/Scalingo/apt-buildpack.git
  https://github.com/Scalingo/nodejs-buildpack.git
  https://github.com/Scalingo/ruby-buildpack.git
TXT
file "Aptfile", "ffmpeg"
file "cron.json", <<~JSON
  {
    "jobs": []
  }
JSON
file "Procfile", <<~TXT
  web: bundle exec puma -C config/puma.rb
  worker: bundle exec good_job start
  postdeploy: rails db:migrate && rails db:seed
TXT

# Linters
########################################
file ".codeclimate.yml", <<~YAML
  version: "2"
  plugins:
    duplication:
      enabled: true
      config:
        languages:
          javascript:
            mass_threshold: 50
    sass-lint:
      enabled: false
      config:
        config: .sass-lint.yml
    eslint:
      enabled: true
      channel: "eslint-5"
      config:
        config: .eslintrc.yml
  exclude_patterns:
    - "node_modules/**"
    - "vendor/**"
    - "db/**"
    - "config/**"
    - "test/**"
    - "docs/**"
YAML
file ".eslintrc.yml", <<~YAML
  env:
    browser: true
  extends: "eslint:recommended"
  rules:
    # key: 0 = allow, 1 = warn, 2 = error

    # Possible Errors
    no-await-in-loop: 1
    no-console: 1
    no-extra-parens: [1, 'all']
    no-template-curly-in-string: 0

    # Best Practices
    accessor-pairs: 0
    array-callback-return: 0
    block-scoped-var: 1
    class-methods-use-this: 0
    complexity: 0
    consistent-return: 0
    curly: [1, 'all']
    default-case: 1
    dot-location: [1, 'property']
    dot-notation: 0
    eqeqeq: 1
    guard-for-in: 0
    max-classes-per-file: 0
    no-alert: 1
    no-caller: 1
    no-div-regex: 1
    no-else-return: 0
    no-empty-function: 1
    no-eq-null: 1
    no-eval: 0
    no-extend-native: 0
    no-extra-bind: 0
    no-extra-label: 1
    no-floating-decimal: 1
    no-implicit-coercion: 1
    no-implied-eval: 1
    no-invalid-this: 0
    no-iterator: 1
    no-labels: 0
    no-lone-blocks: 1
    no-loop-func: 1
    no-magic-numbers: 0
    no-multi-spaces: 1
    no-multi-str: 1
    no-new: 0
    no-new-func: 1
    no-new-wrappers: 1
    no-octal-escape: 1
    no-param-reassign: 1
    no-proto: 1
    no-restricted-globals: 1
    no-restricted-properties: 0
    no-return-assign: 1
    no-return-await: 1
    no-script-url: 1
    no-self-compare: 1
    no-sequences: 1
    no-throw-literal: 1
    no-unmodified-loop-condition: 1
    no-unused-expressions: 1
    no-useless-call: 1
    no-useless-concat: 1
    no-useless-return: 1
    no-void: 1
    no-warning-comments: 0
    prefer-named-capture-group: 0
    prefer-promise-reject-errors: 1
    radix: 1
    require-await: 1
    require-unicode-regexp: 0
    vars-on-top: 1
    wrap-iife: 1
    yoda: 1

    # Strict Mode
    strict: [1, 'safe']

    # Variables
    init-declarations: 0
    no-label-var: 1
    no-implicit-globals: 0
    no-shadow: 1
    no-undef-init: 1
    no-undefined: 1
    no-use-before-define: 1

    # Stylistic Issues
    array-bracket-newline: 0
    array-bracket-spacing: [1, 'never']
    array-element-newline: 0
    block-spacing: [1, 'always']
    brace-style: [1, '1tbs']
    camelcase: 1
    capitalized-comments: 0
    comma-dangle: [1, 'never']
    comma-spacing: [1, { "before": false, "after": true }]
    comma-style: 1
    computed-property-spacing: [1, 'never']
    consistent-this: [1, 'that']
    eol-last: 1
    func-call-spacing: [1, 'never']
    func-name-matching: [1, 'always']
    func-names: 0
    func-style: [1, 'expression']
    function-paren-newline: [1, 'never']
    id-blacklist: 0
    id-length: 0
    id-match: 0
    implicit-arrow-linebreak: 0
    indent: [1, 4]
    jsx-quotes: 0
    key-spacing: 1
    keyword-spacing: 1
    line-comment-position: [1, 'above']
    linebreak-style: [1, 'unix']
    lines-around-comment: 0
    lines-between-class-members: [1, 'always', { exceptAfterSingleLine: true }]
    max-depth: [1, 4]
    max-len: 0
    max-lines: 0
    max-lines-per-function: 0
    max-nested-callbacks: 0
    max-params: [1, 4]
    max-statements: 0
    max-statements-per-line: [1, { max: 1 }]
    multiline-comment-style: 0
    multiline-ternary: 0
    new-cap: 1
    new-parens: 1
    newline-per-chained-call: 1
    no-array-constructor: 0
    no-bitwise: 0
    no-continue: 0
    no-inline-comments: 0
    no-lonely-if: 1
    no-mixed-operators: 0
    no-multi-assign: 1
    no-multiple-empty-lines: 1
    no-negated-condition: 0
    no-nested-ternary: 1
    no-new-object: 0
    no-plusplus: 1
    no-restricted-syntax: 0
    no-tabs: 1
    no-ternary: 0
    no-trailing-spaces: 1
    no-underscore-dangle: 1
    no-unneeded-ternary: 1
    no-whitespace-before-property: 1
    nonblock-statement-body-position: 1
    object-curly-newline: 0
    object-curly-spacing: [1, 'always']
    object-property-newline: 0
    one-var: [1, 'consecutive']
    one-var-declaration-per-line: [1, 'always']
    operator-assignment: [1, 'always']
    operator-linebreak: 0
    padded-blocks: [1, 'never']
    padding-line-between-statements: 0
    prefer-object-spread: 0
    quote-props: 0
    quotes: [1, 'single']
    semi: [1, 'always']
    semi-spacing: [1, { before: false, after: true }]
    semi-style: [1, 'last']
    sort-keys: 0
    sort-vars: 0
    space-before-blocks: [1, 'always']
    space-before-function-paren: [1, 'always']
    space-in-parens: [1, 'never']
    space-infix-ops: 0
    space-unary-ops: [1, { words: true, nonwords: false }]
    spaced-comment: [1, 'always', { markers: ["global", "="] }]
    switch-colon-spacing: [1, { after: true, before: false }]
    template-tag-spacing: [1, 'always']
    unicode-bom: [1, 'never']
    wrap-regex: 1
YAML
file ".sass-lint.yml", <<~YAML
  # Linter Options
  options:
    # Don't merge default rules
    merge-default-rules: false
    # Set the formatter to 'html'
    formatter: html
    # Output file instead of logging results
    output-file: 'linters/sass-lint.html'
    # Raise an error if more than 50 warnings are generated
    max-warnings: 50
  # File Options
  files:
    include:
      - 'app/assets/stylesheets/**/*.s+(a|c)ss'
      - 'docs/themes/**/*.s+(a|c)ss'
    ignore:
      - 'vendor/**/*.*'
  # Rule Configuration
  rules:
    class-name-format: 0
    extends-before-mixins: 2
    extends-before-declarations: 2
    mixins-before-declarations:
      - 2
      -
        exclude:
          - breakpoint
          - breakpoint-next
          - breakpoint-min
          - breakpoint-max
          - breakpoint-infix
          - media-breakpoint-up
          - media-breakpoint-down
          - media-breakpoint-between
          - media-breakpoint-only
          - mq
    no-warn: 1
    no-debug: 1
    hex-length:
      - 2
      -
        style: long
    hex-notation:
      - 2
      -
        style: uppercase
    indentation:
      - 4
      -
        size: 4
    property-sort-order:
      - 1
      -
        order: alphabetical
        ignore-custom-properties: false
YAML

########################################
# After bundle
########################################
after_bundle do
  # Generators: Database + Simple Form + Active Storage + Good Job + Annotate + Home
  ########################################
  rails_command "db:drop db:prepare"
  generate("simple_form:install", "--bootstrap")
  rails_command("active_storage:install")
  generate("good_job:install")
  generate("annotate_rb:install")
  rails_command "db:migrate"
  generate(:controller, "home", "index", "--skip-routes", "--no-test-framework")

  # Routes
  ########################################
  route 'root to: "home#index"'

  # Git
  ########################################
  git :init
  git add: "."
  git commit: "-m 'Initial commit with minimal template from https://github.com/noesya/rails-templates'"
end
