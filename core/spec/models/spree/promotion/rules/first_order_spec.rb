require 'spec_helper'

describe Spree::Promotion::Rules::FirstOrder do
  let(:rule) { Spree::Promotion::Rules::FirstOrder.new }
  let(:order) { mock_model(Spree::Order, :user => nil, :email => nil) }
  let(:user) { mock_model(Spree::LegacyUser) }

  context "without a user or email" do
    it { rule.should_not be_eligible(order) }
    it "sets an error message" do
      rule.eligible?(order)
      expect(rule.eligibility_errors.full_messages.first).
        to eq "You need to login or provide your email before applying this coupon code."
    end
  end

  context "first order" do
    context "for a signed user" do
      context "with no completed orders" do
        before(:each) do
          user.stub_chain(:orders, :complete => [])
        end

        specify do
          order.stub(:user => user)
          rule.should be_eligible(order)
        end

        it "should be eligible when user passed in payload data" do
          rule.should be_eligible(order, :user => user)
        end
      end

      context "with completed orders" do
        before(:each) do
          order.stub(:user => user)
        end

        it "should be eligible when checked against first completed order" do
          user.stub_chain(:orders, :complete => [order])
          rule.should be_eligible(order)
        end

        context "with another order" do
          before { user.stub_chain(:orders, :complete => [mock_model(Spree::Order)]) }
          it { rule.should_not be_eligible(order) }
          it "sets an error message" do
            rule.eligible?(order)
            expect(rule.eligibility_errors.full_messages.first).
              to eq "This coupon code can only be applied to your first order."
          end
        end
      end
    end

    context "for a guest user" do
      let(:email) { 'user@spreecommerce.com' }
      before { order.stub :email => 'user@spreecommerce.com' }

      context "with no other orders" do
        it { rule.should be_eligible(order) }
      end

      context "with another order" do
        before { rule.stub(:orders_by_email => [mock_model(Spree::Order)]) }
        it { rule.should_not be_eligible(order) }
        it "sets an error message" do
          rule.eligible?(order)
          expect(rule.eligibility_errors.full_messages.first).
            to eq "This coupon code can only be applied to your first order."
        end
      end
    end
  end
end
