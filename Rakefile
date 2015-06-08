require "bundler/gem_tasks"

task :icons do
  icon_path = "Contents/Resources/AutomatorApplet.icns"
  %w(Reprint Update).each do |app|
    FileUtils.rm "assets/#{app}.app/#{icon_path}"
    FileUtils.cp "icons/#{app}.icns", "assets/#{app}.app/#{icon_path}"
  end
end
