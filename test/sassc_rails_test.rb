require "test_helper"

class SassRailsTest < MiniTest::Unit::TestCase
  attr_reader :app

  def setup
    Rails.application = nil

    @app = Class.new(Rails::Application)
    @app.config.active_support.deprecation = :log
    @app.config.eager_load = false
    @app.config.root = File.join(File.dirname(__FILE__), "dummy")
    @app.config.log_level = :debug

    # reset config back to default
    @app.config.sass = ActiveSupport::OrderedOptions.new
    @app.config.sass.preferred_syntax = :scss
    @app.config.sass.load_paths       = []

    Rails.backtrace_cleaner.remove_silencers!
  end

  def teardown
    directory = "#{Rails.root}/tmp"
    FileUtils.remove_dir(directory) if File.directory?(directory)
  end

  def render_asset(asset)
    app.assets[asset].to_s
  end

  def initialize!
    @app.initialize!
  end

  def initialize_dev!
    Rails.env = "development"
    @app.initialize!
  end

  def initialize_prod!
    Rails.env = "production"
    @app.initialize!
  end

  def test_setup_works
    initialize!

    asset = render_asset("application.scss")

    assert_equal <<-CSS, asset
.hello {
  color: #FFF; }
    CSS
  end

  def test_raises_sassc_syntax_error
    initialize!

    assert_raises(SassC::SyntaxError) do
      render_asset("syntax_error.scss")
    end
  end

  def test_all_sass_asset_paths_work
    skip

    initialize!

    css_output = render_asset("helpers_test.scss")

    assert_match %r{asset-path:\s*"/assets/rails.png"},                           css_output, 'asset-path:\s*"/assets/rails.png"'
    assert_match %r{asset-url:\s*url\(/assets/rails.png\)},                       css_output, 'asset-url:\s*url\(/assets/rails.png\)'
    assert_match %r{image-path:\s*"/assets/rails.png"},                           css_output, 'image-path:\s*"/assets/rails.png"'
    assert_match %r{image-url:\s*url\(/assets/rails.png\)},                       css_output, 'image-url:\s*url\(/assets/rails.png\)'
  end

  def test_sass_asset_paths_work
    initialize!

    css_output = render_asset("helpers_test.scss")

    assert_match %r{video-path:\s*"/videos/rails.mp4"},                           css_output, 'video-path:\s*"/videos/rails.mp4"'
    assert_match %r{video-url:\s*url\(/videos/rails.mp4\)},                       css_output, 'video-url:\s*url\(/videos/rails.mp4\)'
    assert_match %r{audio-path:\s*"/audios/rails.mp3"},                           css_output, 'audio-path:\s*"/audios/rails.mp3"'
    assert_match %r{audio-url:\s*url\(/audios/rails.mp3\)},                       css_output, 'audio-url:\s*url\(/audios/rails.mp3\)'
    assert_match %r{font-path:\s*"/fonts/rails.ttf"},                             css_output, 'font-path:\s*"/fonts/rails.ttf"'
    assert_match %r{font-url:\s*url\(/fonts/rails.ttf\)},                         css_output, 'font-url:\s*url\(/fonts/rails.ttf\)'
    assert_match %r{font-url-with-query-hash:\s*url\(/fonts/rails.ttf\?#iefix\)}, css_output, 'font-url:\s*url\(/fonts/rails.ttf?#iefix\)'
    assert_match %r{javascript-path:\s*"/javascripts/rails.js"},                  css_output, 'javascript-path:\s*"/javascripts/rails.js"'
    assert_match %r{javascript-url:\s*url\(/javascripts/rails.js\)},              css_output, 'javascript-url:\s*url\(/javascripts/rails.js\)'
    assert_match %r{stylesheet-path:\s*"/stylesheets/rails.css"},                 css_output, 'stylesheet-path:\s*"/stylesheets/rails.css"'
    assert_match %r{stylesheet-url:\s*url\(/stylesheets/rails.css\)},             css_output, 'stylesheet-url:\s*url\(/stylesheets/rails.css\)'

    asset_data_url_regexp = %r{asset-data-url:\s*url\((.*?)\)}
    assert_match asset_data_url_regexp, css_output, 'asset-data-url:\s*url\((.*?)\)'
    asset_data_url_match = css_output.match(asset_data_url_regexp)[1]
    asset_data_url_expected = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyRpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw%" +
    "2FeHBhY2tldCBiZWdpbj0i77u%2FIiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8%2BIDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYxIDY0LjE0MDk0OSwgMjA" +
    "xMC8xMi8wNy0xMDo1NzowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRw" +
    "Oi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDc" +
    "mVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNS4xIE1hY2ludG9zaCIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpCNzY5NDE1QkQ2NkMxMUUwOUUzM0E5Q0E2RTgyQUExQiIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDpCNzY5NDE1Q0" +
    "Q2NkMxMUUwOUUzM0E5Q0E2RTgyQUExQiI%2BIDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOkE3MzcyNTQ2RDY2QjExRTA5RTMzQTlDQTZFODJBQTFCIiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOkI3Njk0M" +
    "TVBRDY2QzExRTA5RTMzQTlDQTZFODJBQTFCIi8%2BIDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY%2BIDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8%2B0HhJ9AAAABBJREFUeNpi%2BP%2F%2FPwNAgAEACPwC%2FtuiTRYAAAAA" +
    "SUVORK5CYII%3D"
    assert_equal asset_data_url_expected, asset_data_url_match
  end

  def test_sass_imports_work_correctly
    initialize!

    css_output = render_asset("imports_test.scss")
    assert_match /main/,                     css_output
    assert_match /top-level/,                css_output
    assert_match /partial-sass/,             css_output
    assert_match /partial-scss/,             css_output
    assert_match /sub-folder-relative-sass/, css_output
    assert_match /sub-folder-relative-scss/, css_output
    assert_match /not-a-partial/,            css_output
    assert_match /plain-old-css/,            css_output
    assert_match /another-plain-old-css/,    css_output
    assert_match /without-css-ext/,          css_output
    assert_match /css-scss-handler/,         css_output
    assert_match /css-sass-handler/,         css_output
    assert_match /css-erb-handler/,          css_output
    assert_match /scss-erb-handler/,         css_output
    assert_match /sass-erb-handler/,         css_output

    # do these two actually test anything?
    # should the extension be changed?
    assert_match /css-sass-erb-handler/,     css_output
    assert_match /css-scss-erb-handler/,     css_output

    assert_match /default-old-css/,          css_output

    # skip for now
    # assert_match /globbed/,                  css_output
    # assert_match /nested-glob/,              css_output
  end

  def test_style_config_item_is_defaulted_to_expanded_in_development_mode
    initialize_dev!
    assert_equal :expanded, Rails.application.config.sass.style
  end

  def test_style_config_item_is_honored_in_development_mode
    @app.config.sass.style = :nested
    initialize_dev!
    assert_equal :nested, Rails.application.config.sass.style
  end

  def test_style_config_item_is_not_honored_if_environment_is_not_development
    initialize_prod!
    assert_equal :compressed, Rails.application.config.sass.style
  end

  def test_context_is_being_passed_to_erb_render
    initialize!

    css_output = render_asset("erb_render_with_context.css.erb")
    assert_match /@font-face/, css_output
  end

  def test_special_characters_compile
    initialize!
    css_output = render_asset("special_characters.scss")
  end

  #test 'sprockets require works correctly' do
  #  skip

  #  within_rails_app('scss_project') do |app_root|
  #    css_output = asset_output('css_application.css')
  #    assert_match /globbed/, css_output

  #    if File.exists?("#{app_root}/log/development.log")
  #      log_file = "#{app_root}/log/development.log"
  #    elsif File.exists?("#{app_root}/log/test.log")
  #      log_file = "#{app_root}/log/test.log"
  #    else
  #      flunk "log file was not created"
  #    end

  #    log_output = File.open(log_file).read
  #    refute_match /Warning/, log_output
  #  end
  #end

  #test 'sprockets directives are ignored within an import' do
  #  skip

  #  css_output = sprockets_render('scss_project', 'import_css_application.css')
  #  assert_match /\.css-application/,        css_output
  #  assert_match /\.import-css-application/, css_output
  #end

  #test 'globbed imports work when new file is added' do
  #  skip

  #  project = 'scss_project'
  #  filename = 'application.scss'

  #  within_rails_app(project) do |tmpdir|
  #    asset_output(filename)

  #    new_file = File.join(tmpdir, 'app', 'assets', 'stylesheets', 'globbed', 'new.scss')
  #    File.open(new_file, 'w') do |file|
  #      file.puts '.new-file-test { color: #000; }'
  #    end

  #    css_output = asset_output(filename)
  #    assert_match /new-file-test/, css_output
  #  end
  #end

  #test 'globbed imports work when globbed file is changed' do
  #  skip

  #  project = 'scss_project'
  #  filename = 'application.scss'

  #  within_rails_app(project) do |tmpdir|
  #    asset_output(filename)

  #    new_file = File.join(tmpdir, 'app', 'assets', 'stylesheets', 'globbed', 'globbed.scss')
  #    File.open(new_file, 'w') do |file|
  #      file.puts '.changed-file-test { color: #000; }'
  #    end

  #    css_output = asset_output(filename)
  #    assert_match /changed-file-test/, css_output
  #  end
  #end
end
