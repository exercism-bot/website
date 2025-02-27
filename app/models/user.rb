class User < ApplicationRecord
  include User::Roles

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable,
    :confirmable, :validatable,
    :omniauthable, omniauth_providers: [:github]
  has_many :auth_tokens, dependent: :destroy

  has_one :profile, dependent: :destroy

  has_many :user_tracks, dependent: :destroy
  has_many :tracks, through: :user_tracks
  has_many :solutions, dependent: :destroy
  has_many :submissions, through: :solutions, dependent: :destroy
  has_many :iterations, through: :solutions

  has_many :activities, class_name: "User::Activity", dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :mentor_discussions, foreign_key: :mentor_id, inverse_of: :mentor, dependent: :destroy,
                                class_name: "Mentor::Discussion"
  has_many :mentor_discussion_posts, as: :author, dependent: :destroy,
                                     class_name: "Mentor::DiscussionPost"
  has_many :mentor_testimonials, foreign_key: :mentor_id, inverse_of: :mentor, dependent: :destroy,
                                 class_name: "Mentor::Testimonial"

  has_many :reputation_tokens, class_name: "User::ReputationToken", dependent: :destroy

  has_many :acquired_badges, dependent: :destroy
  has_many :badges, through: :acquired_badges

  has_many :authorships, class_name: "Exercise::Authorship", dependent: :destroy
  has_many :authored_exercises, through: :authorships, source: :exercise

  has_many :contributorships, class_name: "Exercise::Contributorship", dependent: :destroy
  has_many :contributed_exercises, through: :contributorships, source: :exercise
  has_many :scratchpad_pages, dependent: :destroy

  has_many :track_mentorships, dependent: :destroy
  has_many :mentored_tracks, through: :track_mentorships, source: :track

  # TODO: Validate presence of name

  validates :handle, uniqueness: { case_sensitive: false }, handle_format: true

  has_one_attached :avatar

  before_create do
    self.name = self.handle if self.name.blank?
  end

  def self.for!(param)
    return param if param.is_a?(User)
    return find_by!(id: param) if param.is_a?(Numeric)

    find_by!(handle: param)
  end

  def to_param
    handle
  end

  def formatted_reputation(*args)
    rep = reputation(*args)
    User::FormatReputation.(rep)
  end

  def reputation(track_slug: nil, category: nil)
    return super() unless track_slug || category

    raise if track_slug && category

    category = "track_#{track_slug}" if track_slug

    q = reputation_tokens
    q.where!(category: category) if category
    q.sum(:value)
  end

  def joined_track?(track)
    !!UserTrack.for(self, track)
  end

  def unrevealed_badges
    acquired_badges.unrevealed.joins(:badge)
  end

  def has_badge?(slug)
    badge = Badge.find_by_slug!(slug) # rubocop:disable Rails/DynamicFindBy
    acquired_badges.where(badge_id: badge.id).exists?
  end

  # TODO: Order by rarity
  def featured_badges
    badges.limit(5)
  end

  # TODO: This needs fleshing out for mentors
  def may_view_solution?(solution)
    id == solution.user_id
  end

  def onboarded?
    accepted_privacy_policy_at.present? &&
      accepted_terms_at.present?
  end

  # TODO
  def avatar_url
    return Rails.application.routes.url_helpers.url_for(avatar) if avatar.attached?

    # TOOD: Read correct s3 bucket
    # TODO: Add this image to the repo etc
    super || "https://100k-faces.glitch.me/random-image?r=#{SecureRandom.hex(3)}"
    # super || "https://exercism-icons-staging.s3.eu-west-2.amazonaws.com/placeholders/user-avatar.svg"
  end

  # TODO
  def languages_spoken
    %w[english spanish]
  end

  def mentor?
    became_mentor_at.present?
  end

  # TODO: Remove if not used by launch
  # def favorited_by?(mentor)
  #   relationship = Mentor::StudentRelationship.find_by(student: self, mentor: mentor)

  #   relationship ? relationship.favorited? : false
  # end
end
