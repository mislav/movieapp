require 'guard/guard'

guard 'livereload', :apply_js_live => false, :grace_period => 0 do
  ext = %w[js coffee css scss sass png gif html erb]

  watch(%r{.+\.(#{ext.join('|')})$}) do |match|
    file = match[0]
    file = File.join(File.dirname(file), 'application.css') if file =~ /\.(s[ca]ss|css)$/
    file
  end
end
