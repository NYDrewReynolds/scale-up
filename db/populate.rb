require 'populator'

class Populate

  def run
    create_known_users
    create_categories
    create_borrowers(30000)
    create_lenders(200000)
    create_orders
  end

  def lenders
    User.where(role: 0)
  end

  def borrowers
    User.where(role: 1)
  end

  def orders
    Order.all
  end

  def create_known_users
    User.create(name: "Jorge", email: "jorge@example.com", password: "password")
    User.create(name: "Rachel", email: "rachel@example.com", password: "password")
    User.create(name: "Josh", email: "josh@example.com", password: "password", role: 1)
  end

  def create_lenders(quantity)
    User.populate(quantity) do |user|
      user.name = Faker::Name.name
      user.password_digest = "password"
      user.email = Faker::Internet.email
      user.role = 0
    end
  end

  def create_borrowers(quantity)
    categories = Category.all

    User.populate(quantity) do |user|
      user.name = Faker::Name.name
      user.password_digest = "password"
      user.email = Faker::Internet.email
      user.role = 1
      LoanRequest.populate(17) do |lr|
        lr.user_id = user.id
        lr.title = Faker::Commerce.product_name
        lr.description = Faker::Company.catch_phrase
        lr.amount = "200"
        lr.status = [0, 1].sample
        lr.requested_by_date = Faker::Time.between(7.days.ago, 3.days.ago)
        lr.contributed = "0"
        lr.repayment_rate = "weekly"
        lr.repayment_begin_date = Faker::Time.between(3.days.ago, Time.now)

        LoanRequestsCategory.populate(1) do |lrc|
          lrc.category_id = categories.sample.id
          lrc.loan_request_id = lr.id
        end
      end
    end
  end

  def create_categories
    Category.populate(15) do |cat|
      cat.title = Faker::Commerce.department
      cat.description = Faker::Lorem.sentence
    end
  end

  def create_orders
    loan_requests = LoanRequest.all.sample(50000)

    possible_donations = %w(25, 50, 75, 100, 125, 150, 175, 200)

    loan_requests.each do |request|
      donate = possible_donations.sample
      lender = lenders.sample(1)
      order = Order.create(cart_items:
                               {"#{request.id}" => donate},
                           user_id: lender.id)
      order.update_contributed(lender)
      puts "Created Order for Request #{request.title} by Lender #{lender.name}"
    end

  end

end

Populate.new.run
