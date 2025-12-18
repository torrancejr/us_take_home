# frozen_string_literal: true

class AgencySnapshot < ApplicationRecord
  belongs_to :agency

  validates :snapshot_date, presence: true, uniqueness: { scope: :agency_id }

  def parsed_metrics
    JSON.parse(metrics_json || "{}")
  rescue JSON::ParserError
    {}
  end
end

