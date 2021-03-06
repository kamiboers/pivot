require "rails_helper"

RSpec.feature "User can view own loan requests" do
  scenario "existing user can view their loan requests" do
    create_user
    user = User.last
    create_loan_request(2)
    user.loan_requests = LoanRequest.all
    request = user.loan_requests.first
    
    visit '/login'
    fill_in "Username", with: user.username
    fill_in "Password", with: "password"
    click_on "Log in"

    click_on "View My Loan Requests"

    expect(page).to have_content ActionController::Base.helpers.number_to_currency(request.amount)
    expect(page).to have_content request.rate

  end
end
