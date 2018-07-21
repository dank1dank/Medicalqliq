Feature: 
  As an qliq iOS developer
  I want to test qliq Login functionality

Background:
  Given I reset the iphone app

Scenario: 
  Successful Login using Email and Password

  When I use the keyboard to fill in the textfield marked "EmailInput" with "kkurapati@hospital.com"
  When I use the keyboard to fill in the textfield marked "PasswordInput" with "123456"
  When I hit done on the keyboard
  Then I wait to see "Set PIN Later"
  When I touch "Set PIN Later"
  Then I quit and cleanup the app
