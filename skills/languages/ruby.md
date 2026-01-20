---
name: ruby-patterns
description: Ruby specific patterns, Rails, and best practices.
---

# Ruby Patterns

Language-specific patterns for Ruby and Ruby on Rails applications.

## Ruby Fundamentals

### Class Definition
```ruby
class User
  attr_reader :id, :name, :email, :created_at
  attr_accessor :active

  def initialize(name:, email:, id: SecureRandom.uuid, active: true)
    @id = id
    @name = name
    @email = email
    @created_at = Time.current
    @active = active
    freeze_if_immutable
  end

  def active?
    @active
  end

  def to_h
    {
      id: id,
      name: name,
      email: email,
      created_at: created_at,
      active: active
    }
  end

  private

  def freeze_if_immutable
    # Freeze to make immutable if needed
  end
end
```

### Data Class (Ruby 3.2+)
```ruby
# Immutable value object
User = Data.define(:id, :name, :email, :created_at, :active) do
  def initialize(id: SecureRandom.uuid, name:, email:, created_at: Time.current, active: true)
    super
  end

  def active?
    active
  end
end

# Usage
user = User.new(name: "John", email: "john@example.com")
updated_user = user.with(name: "Jane")  # Immutable update
```

### Struct
```ruby
# Quick data structure
UserStruct = Struct.new(:id, :name, :email, :active, keyword_init: true) do
  def active?
    active
  end
end

user = UserStruct.new(id: "123", name: "John", email: "john@example.com", active: true)
```

### Modules and Mixins
```ruby
module Searchable
  extend ActiveSupport::Concern

  included do
    scope :search, ->(query) { where("name ILIKE ?", "%#{query}%") }
  end

  class_methods do
    def find_by_query(query)
      search(query).first
    end
  end
end

class User < ApplicationRecord
  include Searchable
end
```

### Blocks, Procs, and Lambdas
```ruby
# Block
users.each { |user| puts user.name }

users.map do |user|
  {
    id: user.id,
    display_name: user.name.upcase
  }
end

# Proc
my_proc = Proc.new { |x| x * 2 }
my_proc.call(5)  # => 10

# Lambda (preferred for strict arity)
my_lambda = ->(x) { x * 2 }
my_lambda.call(5)  # => 10

# Method reference
users.map(&:name)  # Same as users.map { |u| u.name }
```

## Rails Patterns

### Model
```ruby
class User < ApplicationRecord
  # Associations
  has_many :orders, dependent: :destroy
  has_many :products, through: :orders
  belongs_to :organization, optional: true

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_domain, ->(domain) { where("email LIKE ?", "%@#{domain}") }

  # Callbacks
  before_validation :normalize_email
  after_create :send_welcome_email

  # Enums
  enum status: { pending: 0, active: 1, suspended: 2 }

  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def deactivate!
    update!(active: false, deactivated_at: Time.current)
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end
end
```

### Controller
```ruby
class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :update, :destroy]

  def index
    @users = User.active
                 .page(params[:page])
                 .per(params[:per_page] || 20)

    render json: @users, each_serializer: UserSerializer
  end

  def show
    render json: @user, serializer: UserDetailSerializer
  end

  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user, status: :created, location: api_v1_user_url(@user)
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      render json: @user
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    head :no_content
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :active)
  end
end
```

### Service Object
```ruby
class Users::CreateService
  include ActiveModel::Validations

  attr_reader :user, :params

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def initialize(params)
    @params = params
    @name = params[:name]
    @email = params[:email]
  end

  def call
    return failure(errors) unless valid?

    @user = User.new(params)

    if user.save
      send_notifications
      success(user)
    else
      failure(user.errors)
    end
  end

  private

  attr_reader :name, :email

  def send_notifications
    UserMailer.welcome(user).deliver_later
    Analytics.track("user_created", user_id: user.id)
  end

  def success(data)
    Result.new(success: true, data: data)
  end

  def failure(errors)
    Result.new(success: false, errors: errors)
  end

  Result = Struct.new(:success, :data, :errors, keyword_init: true) do
    def success?
      success
    end

    def failure?
      !success
    end
  end
end

# Usage in controller
result = Users::CreateService.new(user_params).call

if result.success?
  render json: result.data, status: :created
else
  render json: { errors: result.errors }, status: :unprocessable_entity
end
```

### Query Object
```ruby
class Users::SearchQuery
  def initialize(relation = User.all)
    @relation = relation
  end

  def call(params)
    @relation = filter_by_status(params[:status])
    @relation = filter_by_query(params[:q])
    @relation = filter_by_date_range(params[:from], params[:to])
    @relation = sort_by(params[:sort], params[:order])
    @relation
  end

  private

  def filter_by_status(status)
    return @relation if status.blank?
    @relation.where(status: status)
  end

  def filter_by_query(query)
    return @relation if query.blank?
    @relation.where("name ILIKE :q OR email ILIKE :q", q: "%#{query}%")
  end

  def filter_by_date_range(from, to)
    @relation = @relation.where("created_at >= ?", from) if from.present?
    @relation = @relation.where("created_at <= ?", to) if to.present?
    @relation
  end

  def sort_by(sort, order)
    return @relation.recent if sort.blank?

    direction = order == "asc" ? :asc : :desc
    @relation.order(sort => direction)
  end
end

# Usage
users = Users::SearchQuery.new.call(params)
```

### Form Object
```ruby
class UserRegistrationForm
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :name, :email, :password, :password_confirmation, :terms_accepted

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 },
                       confirmation: true
  validates :terms_accepted, acceptance: true

  def save
    return false unless valid?

    user = User.new(name: name, email: email, password: password)
    user.save
  end

  def persisted?
    false
  end
end
```

### Serializer
```ruby
class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :created_at, :active

  has_many :orders

  def created_at
    object.created_at.iso8601
  end
end

# Or with Blueprinter
class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :email, :active

  field :created_at do |user|
    user.created_at.iso8601
  end

  association :orders, blueprint: OrderBlueprint

  view :detailed do
    association :organization, blueprint: OrganizationBlueprint
  end
end
```

### Background Jobs
```ruby
class SendWelcomeEmailJob < ApplicationJob
  queue_as :default
  retry_on Net::SMTPError, wait: 5.seconds, attempts: 3

  def perform(user_id)
    user = User.find(user_id)
    UserMailer.welcome(user).deliver_now
  end
end

# Sidekiq worker
class HardWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 5

  def perform(user_id)
    user = User.find(user_id)
    # Heavy processing
  end
end
```

## Error Handling

```ruby
# Custom exceptions
module Errors
  class BaseError < StandardError
    attr_reader :code, :details

    def initialize(message = nil, code: nil, details: nil)
      @code = code
      @details = details
      super(message)
    end
  end

  class NotFoundError < BaseError
    def initialize(resource, id)
      super("#{resource} with id #{id} not found", code: "NOT_FOUND")
    end
  end

  class ValidationError < BaseError
    def initialize(errors)
      super("Validation failed", code: "VALIDATION_ERROR", details: errors)
    end
  end
end

# Controller error handling
class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: "Not found" }, status: :not_found
  end

  rescue_from Errors::NotFoundError do |e|
    render json: { error: e.message, code: e.code }, status: :not_found
  end

  rescue_from Errors::ValidationError do |e|
    render json: { error: e.message, code: e.code, details: e.details },
           status: :unprocessable_entity
  end
end
```

## Testing with RSpec

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
  end

  describe "associations" do
    it { is_expected.to have_many(:orders).dependent(:destroy) }
    it { is_expected.to belong_to(:organization).optional }
  end

  describe "#full_name" do
    it "returns combined first and last name" do
      user = build(:user, first_name: "John", last_name: "Doe")
      expect(user.full_name).to eq("John Doe")
    end
  end
end

# spec/requests/users_spec.rb
RSpec.describe "Users API", type: :request do
  describe "GET /api/v1/users" do
    let!(:users) { create_list(:user, 3) }

    it "returns all users" do
      get api_v1_users_path

      expect(response).to have_http_status(:ok)
      expect(json_response.size).to eq(3)
    end
  end

  describe "POST /api/v1/users" do
    let(:valid_params) { { user: { name: "Test", email: "test@example.com" } } }

    it "creates a new user" do
      expect {
        post api_v1_users_path, params: valid_params
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end
end

# spec/services/users/create_service_spec.rb
RSpec.describe Users::CreateService do
  describe "#call" do
    context "with valid params" do
      let(:params) { { name: "Test", email: "test@example.com" } }

      it "creates a user" do
        result = described_class.new(params).call

        expect(result).to be_success
        expect(result.data).to be_a(User)
      end
    end

    context "with invalid params" do
      let(:params) { { name: "", email: "invalid" } }

      it "returns failure" do
        result = described_class.new(params).call

        expect(result).to be_failure
        expect(result.errors).to be_present
      end
    end
  end
end
```

## Project Structure

```
app/
├── controllers/
│   ├── api/
│   │   └── v1/
│   │       └── users_controller.rb
│   └── application_controller.rb
├── models/
│   └── user.rb
├── services/
│   └── users/
│       ├── create_service.rb
│       └── update_service.rb
├── queries/
│   └── users/
│       └── search_query.rb
├── serializers/
│   └── user_serializer.rb
├── jobs/
│   └── send_welcome_email_job.rb
└── mailers/
    └── user_mailer.rb

spec/
├── models/
├── requests/
├── services/
└── factories/
```

## Formatters & Linters

- **RuboCop**: Linting and style enforcement
- **Standard**: Opinionated Ruby style guide
- **Brakeman**: Security analysis
- **Reek**: Code smell detection

## Debug Statements to Remove

```ruby
# Remove before committing
puts
p
pp
print
binding.pry
binding.irb
byebug
debugger
Rails.logger.debug (if only for debugging)
```
