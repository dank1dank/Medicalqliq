Feature:
    I should be able to use Secure messaging provided by qliq app
  
Scenario:
    Send a test message to one of my contact
	
	Given I touch "tabBarButton contacts" 
	Then I touch "qliq Medical Center"
	Then I scroll down the table
    Given I select "Ravi Ada, MD" in the contact table
	
	Then I prepare the message as follows:
	| message   | This is from Frankified qliq |
	| regarding | Automated Test               |
	| ackreq    | NO                           |