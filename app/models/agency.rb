# frozen_string_literal: true

class Agency < ApplicationRecord
  has_many :agency_snapshots, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end

