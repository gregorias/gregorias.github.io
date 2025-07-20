build:
  bundle exec jekyll build


test: build
  bundle exec htmlproofer _site \
      --no-check_external_hash \
      --disable_external \
      --ignore-urls "/^http:\/\/127.0.0.1/,/^http:\/\/0.0.0.0/,/^http:\/\/localhost/,/fonts.googleapis.com/,/fonts.gstatic.com/,/linkedin.com\/in\/grzegorz-milka-55270490/,/twitter.com\/intent\/tweet/,/archive.ph/,/statmodeling.stat.columbia.edu/"
