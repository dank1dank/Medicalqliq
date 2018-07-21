def app_path
  ENV['APP_BUNDLE_PATH'] || (defined?(APP_BUNDLE_PATH) && APP_BUNDLE_PATH)
end


Given /^I reset the (iphone|ipad) app$/ do |device|
  #USERDEFAULTS_PLIST = "Library/Preferences/com.yourcompany.#{APPNAME}.dist.plist"
  steps "Given I launch the app"
end


Given /^I launch the app$/ do
  # latest sdk and iphone by default
  launch_app app_path
end

Given /^I quit and cleanup the app$/ do
	steps "When I quit the simulator"
	APPLICATIONS_DIR = "/Users/#{ENV['USER']}/Library/Application Support/iPhone Simulator/5.0/Applications"
	APP_PLIST = "qliq copy.app/Info.plist"
	QLIQDATABASE = "Documents/qliq.sqlite"
	if Dir::exists?("#{APPLICATIONS_DIR}")
		Dir.foreach(APPLICATIONS_DIR) do |item|
			next if item == '.' or item == '..'
			if File::exists?("#{APPLICATIONS_DIR}/#{item}/#{QLIQDATABASE}")
				FileUtils.rm "#{APPLICATIONS_DIR}/#{item}/#{QLIQDATABASE}"
			end
			if File::exists?("#{APPLICATIONS_DIR}/#{item}/#{APP_PLIST}")
				FileUtils.rm "#{APPLICATIONS_DIR}/#{item}/#{APP_PLIST}"
			end
			
		end
	end 
	if Dir::exists?("#{APPLICATIONS_DIR}")
		FileUtils.rm_rf "#{APPLICATIONS_DIR}"
	end
end

Given /^I launch the app using iOS (\d\.\d)$/ do |sdk|
  # You can grab a list of the installed SDK with sim_launcher
  # > run sim_launcher from the command line
  # > open a browser to http://localhost:8881/showsdks
  # > use one of the sdk you see in parenthesis (e.g. 4.2)
  launch_app app_path, sdk
end

Given /^I launch the app using iOS (\d\.\d) and the (iphone|ipad) simulator$/ do |sdk, version|
  launch_app app_path, sdk, version
end

Then /^I press the home button$/ do
	press_home_on_simulator
end