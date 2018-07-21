When /^User "([^\"]*)" logs on skipping PIN setup$/ do |email|
	steps "When I use the keyboard to fill in the textfield marked \"EmailInput\" with \"#{email}\""
	steps "When I use the keyboard to fill in the textfield marked \"PasswordInput\" with \"123456\""
	steps "When I hit done on the keyboard"
	steps "Then I wait to see \"Set PIN Later\""
	steps "And I touch \"Set PIN Later\""
end

Then /^I save a screenshot with prefix (\w+)$/ do |prefix|
 filename = prefix + Time.now.to_i.to_s
 %x[screencapture #{filename}.png]
end

Then /^I prepare the message as follows:$/ do |table|
	@message = table.rows_hash
	steps "When I use the keyboard to fill in the textfield marked \"RegardingInput\" with \"#{@message["regarding"]}\""
	steps "When I use the keyboard to fill in the textfield marked \"ChatInput\" with \"#{@message["message"]}\""
end

When /^I select "([^\"]*)" in the contact table$/ do |select_cell|
	steps "When I use the keyboard to fill in the textfield marked \"ContactSearchInput\" with \"#{select_cell}\""
	steps "Then I touch \"#{select_cell}\""
end

When /^I scroll down the table$/ do
	table_view_selector =  "view marked:'Empty list'"
	frankly_map(table_view_selector, "scrollToCell", "1", "10")
end