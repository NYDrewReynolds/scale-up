require "logger"
require "pry"
require "capybara"
require 'capybara/poltergeist'
require "faker"
require "active_support"
require "active_support/core_ext"

module LoadScript
  class Session
    include Capybara::DSL
    attr_reader :host

    def initialize(host = nil)
      Capybara.default_driver = :poltergeist
      @host = host || "http://localhost:3000"
    end

    def logger
      @logger ||= Logger.new("./log/requests.log")
    end

    def session
      @session ||= Capybara::Session.new(:poltergeist)
    end

    def run
      while true
        run_action(actions.sample)
      end
    end

    def run_action(name)
      benchmarked(name) do
        send(name)
      end
    rescue Capybara::Poltergeist::TimeoutError
      logger.error("Timed out executing Action: #{name}. Will continue.")
    end

    def benchmarked(name)
      logger.info "Running action #{name}"
      start = Time.now
      val = yield
      logger.info "Completed #{name} in #{Time.now - start} seconds"
      val
    end

    def actions
      [:browse_loan_requests, :user_browses_loan_requests, :user_browses_single_loan_request, :sign_up_as_lender, :sign_up_as_borrower]
    end

    def log_in(email="jorge@example.com", pw="password")
      log_out
      session.visit host
      session.click_link("Login")
      session.fill_in("Email", with: email)
      session.fill_in("Password", with: pw)
      session.click_link_or_button("Log In")
    end

    def browse_loan_requests
      session.visit "#{host}/browse"
      puts "browsing loan request"
      session.all(".lr-about").sample.click
    end

    def log_out
      session.visit host
      if session.has_content?("Log out")
        session.find("#logout").click
      end
    end

    def new_user_name
      "#{Faker::Name.name} #{Time.now.to_i}"
    end

    def new_user_email(name)
      "TuringPivotBots+#{name.split.join}@gmail.com"
    end

    def sign_up_as_lender(name = new_user_name)
      puts "sign up as lender"
      log_out
      session.find("#sign-up-dropdown").click
      session.find("#sign-up-as-lender").click
      session.fill_in("user_name", with: name)
      session.fill_in("user_email", with: new_user_email(name))
      session.fill_in("user_password", with: "password")
      session.fill_in("user_password_confirmation", with: "password")
      session.click_link_or_button "Create Account"
    end

    def categories
      ["Agriculture", "Education", "Community"]
    end

    def user_browses_loan_requests
      log_in
      session.visit "#{host}/browse"
      puts "user is browsing loan requests"
      session.find('.next_page').click
    end

    def user_browses_single_loan_request
      puts "user is browsing single loan request"
      log_in
      session.visit "#{host}/#{LoanRequest.all.limit(1).first.id}"
    end

    def sign_up_as_borrower(name = new_user_name)
      puts "sign up as borrower"
      log_out
      session.find("#sign-up-dropdown").click
      session.find("#sign-up-as-borrower").click
      session.fill_in("user_name", with: name)
      session.fill_in("user_email", with: new_user_email(name))
      session.fill_in("user_password", with: "password")
      session.fill_in("user_password_confirmation", with: "password")
      session.click_link_or_button "Create Account"
    end

    def new_borrower_loan_request
      puts "new borrower makes loan request"
      log_out
      sign_up_as_borrower
      session.click_link_or_button "Create Loan Request"
      session.fill_in("loan_request_title", with: "Title")
      session.fill_in("loan_request_description", with: "Descriptionnn")
      session.fill_in("loan_request_image_url", with: "http://google.com/image.jpg")
      session.fill_in("loan_request_requested_by_date", with: "#{Faker::Time.between(7.days.ago, 3.days.ago)}")
      session.fill_in("loan_request_repayment_begin_date", with: "#{Faker::Time.between(3.days.ago, Time.now)}")
      session.find("#loan_request_category").click
      session.click_link_or_button "Agriculture"
      session.fill_in("loan_request_amount", with: "500")
      session.click_link_or_button "Submit"
    end

    def lender_makes_loan
      log_out
      sign_up_as_lender
    #   make loan
    end

    #[X] Anonymous user browses loan requests
    #[X] User browses pages of loan requests
    #[] User browses categories
    #[] User browses pages of categories
    #[X] User views individual loan request
    #[X] New user signs up as lender
    #[X] New user signs up as borrower
    #[X] New borrower creates loan request
    #[] Lender makes loan

  end
end
