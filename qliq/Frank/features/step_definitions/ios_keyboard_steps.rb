def send_command ( command )
  %x{osascript<<APPLESCRIPT
tell application "System Events"
  tell application "iPhone Simulator" to activate
  keystroke "#{command}"
  delay 1
  key code 36
end tell
APPLESCRIPT}
end

When /^I send the command "([^\\"]*)"$/ do |cmd|
  send_command(cmd)
end

When /^I send the command "([^"]*)" (\d+) times$/ do |cmd, times|
  i = 0
  while i < times.to_i
    send_command(cmd)
    i += 1
  end
end

When /^I send the following commands:$/ do |table|
  table.hashes.each do |row|
    steps "When I send the command \\"#{row['command']}\\"
  #{row['times']} times"
    send_command(row['command'])
  end
end

When /^I hit (return|done) on the keyboard$/ do |key|
    %x{osascript<<APPLESCRIPT
        tell application "System Events"
		tell application "iPhone Simulator" to activate
		key code 36
        end tell
	APPLESCRIPT}
end

When /^I use the keyboard to fill in the textfield marked "([^\"]*)" with "([^\"]*)"$/ do |text_field_mark, text_to_type|
	text_field_selector =  "view marked:'#{text_field_mark}'"
	check_element_exists( text_field_selector )
	#   touch( text_field_selector )
	frankly_map( text_field_selector, 'becomeFirstResponder' )
	frankly_map( text_field_selector, 'setText:', text_to_type )
	#   frankly_map( text_field_selector, 'endEditing:', true )
end