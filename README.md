# Rails Templates

## Minimal app

Bootstrap + Simple Form + Good Job + Active Storage (Scaleway)

```
rails new \
  --database=postgresql \
  --skip-docker \
  --skip-action-mailbox \
  --skip-action-text \
  --skip-action-cable \
  --skip-asset-pipeline \
  --skip-javascript \
  --skip-hotwire \
  --skip-thruster \
  --skip-rubocop \
  --skip-brakeman \
  --skip-ci \
  --skip-kamal \
  --skip-solid \
  --skip-devcontainer \
  --template=https://raw.githubusercontent.com/noesya/rails-templates/main/minimal.rb \
  APP_NAME
```

## Credits

Thanks [Le Wagon](https://github.com/lewagon/rails-templates) for the inspiration ❤️
