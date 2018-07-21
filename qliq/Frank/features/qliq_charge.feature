Feature:
   As a qliqCharge user when I login, I should see my main view and I should
   see My patients, My Group's patients, Appointments, Census. I should be able to 
   change the date and see patients for different dates. I should be able to add charges
   to my patient. Hand off my patient to my colleague. 

Scenario:
    Login and view my patients in each facility that I go to
	
    Given I reset the iphone app
    When User "kkurapati@hospital.com" logs on skipping PIN setup
    Then I touch "btn group off"
    When I touch the first table cell
    Then I touch "Group"
	Then I wait for 2 seconds

Scenario:
    Test chat functionality

    Then I touch "btn chat on"
