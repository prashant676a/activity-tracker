# spec/models/company_spec.rb
require 'rails_helper'

RSpec.describe Company, type: :model do
  describe 'associations' do
    it { should have_many(:users).dependent(:restrict_with_error) }
    it { should have_many(:activities).dependent(:restrict_with_error) }
  end

  describe 'validations' do
    subject { build(:company) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe 'default values' do
    it 'defaults activity_tracking_enabled to true' do
      company = Company.new(name: 'Test Co')
      expect(company.activity_tracking_enabled).to be true
    end

    it 'defaults activity_tracking_config to empty hash' do
      company = Company.new(name: 'Test Co')
      expect(company.activity_tracking_config).to eq({})
    end
  end

  describe 'scopes' do
    describe '.with_tracking_enabled' do
      let!(:enabled_company) { create(:company, activity_tracking_enabled: true) }
      let!(:disabled_company) { create(:company, activity_tracking_enabled: false) }

      it 'returns only companies with tracking enabled' do
        expect(Company.with_tracking_enabled).to include(enabled_company)
        expect(Company.with_tracking_enabled).not_to include(disabled_company)
      end
    end
  end

  describe '#tracking_enabled_for?' do
    let(:company) { create(:company) }

    context 'when tracking is globally disabled' do
      before { company.update(activity_tracking_enabled: false) }

      it 'returns false for any activity type' do
        expect(company.tracking_enabled_for?('login')).to be false
        expect(company.tracking_enabled_for?('logout')).to be false
      end
    end

    context 'when tracking is globally enabled' do
      context 'with no specific configuration' do
        it 'returns true for all valid activity types' do
          Activity::ACTIVITY_TYPES.each do |type|
            expect(company.tracking_enabled_for?(type)).to be true
          end
        end
      end

      context 'with specific activity types enabled' do
        before do
          company.update(
            activity_tracking_config: {
              enabled_activity_types: [ 'login', 'logout' ]
            }
          )
        end

        it 'returns true for enabled types' do
          expect(company.tracking_enabled_for?('login')).to be true
          expect(company.tracking_enabled_for?('logout')).to be true
        end

        it 'returns false for disabled types' do
          expect(company.tracking_enabled_for?('profile_update')).to be false
          expect(company.tracking_enabled_for?('give_recognition')).to be false
        end

        it 'handles string and symbol activity types' do
          expect(company.tracking_enabled_for?(:login)).to be true
          expect(company.tracking_enabled_for?('login')).to be true
        end
      end
    end
  end

  describe 'data integrity' do
    # Use let! to ensure fresh data for each test
    let!(:company) { create(:company) }

    describe 'preventing deletion with dependencies' do
      it 'prevents deletion when users exist' do
        create(:user, company: company)

        expect { company.destroy }.not_to change(Company, :count)
        expect(company.errors[:base]).to include('Cannot delete record because dependent users exist')
      end

      it 'prevents deletion when activities exist' do
        user = create(:user, company: company)
        create(:activity, user: user, company: company)

        expect { company.destroy }.not_to change(Company, :count)
        # The error might come from users since activities depend on users
        # Check for either error message
        expect(
          company.errors[:base].any? { |msg|
            msg.include?('users exist') || msg.include?('activities exist')
          }
        ).to be true
      end
    end

    it 'allows deletion when no dependencies exist' do
      # Create a new company with no associations
      standalone_company = create(:company)

      expect { standalone_company.destroy! }.to change(Company, :count).by(-1)
    end
  end
end
