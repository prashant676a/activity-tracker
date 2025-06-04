# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should belong_to(:company) }
    it { should have_many(:activities).dependent(:restrict_with_error) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:email).scoped_to(:company_id) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid-email').for(:email) }
    it { should validate_inclusion_of(:role).in_array(%w[user company_admin admin]) }
  end

  describe 'discard (soft delete)' do
    let(:user) { create(:user) }

    it 'includes Discard::Model' do
      expect(User.ancestors).to include(Discard::Model)
    end

    it 'can be discarded' do
      expect { user.discard }.to change { user.discarded? }.from(false).to(true)
    end

    it 'sets discarded_at timestamp' do
      user.discard
      expect(user.discarded_at).to be_within(1.second).of(Time.current)
    end

    it 'can be undiscarded' do
      user.discard
      expect { user.undiscard }.to change { user.discarded? }.from(true).to(false)
    end

    it 'is excluded from default scope when discarded' do
      user.discard
      expect(User.all).not_to include(user)
      expect(User.with_discarded).to include(user)
    end
  end

  describe 'scopes' do
    let!(:active_user) { create(:user) }
    let!(:discarded_user) { create(:user, :discarded) }
    let!(:admin) { create(:user, :admin) }
    let!(:company_admin) { create(:user, :company_admin) }

    describe '.active' do
      it 'returns only kept users' do
        expect(User.active).to include(active_user, admin, company_admin)
        expect(User.active).not_to include(discarded_user)
      end

      it 'is an alias for kept' do
        expect(User.active.to_sql).to eq(User.kept.to_sql)
      end
    end

    describe '.admins' do
      it 'returns admin and company_admin users' do
        expect(User.admins).to include(admin, company_admin)
        expect(User.admins).not_to include(active_user)
      end

      it 'includes discarded admins' do
        admin.discard
        expect(User.admins.with_discarded).to include(admin)
      end
    end
  end

  describe 'instance methods' do
    describe '#admin?' do
      it 'returns true for admin role' do
        user = build(:user, role: 'admin')
        expect(user.admin?).to be true
      end

      it 'returns false for other roles' do
        user = build(:user, role: 'user')
        expect(user.admin?).to be false

        user = build(:user, role: 'company_admin')
        expect(user.admin?).to be false
      end
    end

    describe '#company_admin?' do
      it 'returns true for company_admin role' do
        user = build(:user, role: 'company_admin')
        expect(user.company_admin?).to be true
      end

      it 'returns false for other roles' do
        user = build(:user, role: 'user')
        expect(user.company_admin?).to be false

        user = build(:user, role: 'admin')
        expect(user.company_admin?).to be false
      end
    end

    describe '#can_view_activities?' do
      it 'returns true for admin' do
        user = build(:user, :admin)
        expect(user.can_view_activities?).to be true
      end

      it 'returns true for company_admin' do
        user = build(:user, :company_admin)
        expect(user.can_view_activities?).to be true
      end

      it 'returns false for regular user' do
        user = build(:user, role: 'user')
        expect(user.can_view_activities?).to be false
      end
    end
  end

  describe 'email uniqueness within company' do
    let(:company1) { create(:company) }
    let(:company2) { create(:company) }

    it 'allows same email in different companies' do
      create(:user, email: 'test@example.com', company: company1)
      user2 = build(:user, email: 'test@example.com', company: company2)
      expect(user2).to be_valid
    end

    it 'prevents duplicate email in same company' do
      create(:user, email: 'test@example.com', company: company1)
      user2 = build(:user, email: 'test@example.com', company: company1)
      expect(user2).not_to be_valid
      expect(user2.errors[:email]).to include('has already been taken')
    end
  end

  describe 'data integrity' do
    let(:user) { create(:user) }

    it 'prevents hard deletion when activities exist' do
      create(:activity, user: user)
      expect { user.destroy }.not_to change(User, :count)
      expect(user.errors[:base]).to include('Cannot delete record because dependent activities exist')
    end

    it 'allows soft deletion when activities exist' do
      create(:activity, user: user)
      expect { user.discard }.to change { user.discarded? }.from(false).to(true)
      expect(user.activities).to exist
    end
  end
end
