# frozen_string_literal: true

module Api
  class AgenciesController < ApplicationController
    skip_before_action :verify_authenticity_token

    def index
      agencies = Agency.order(:name).includes(:agency_snapshots)

      render json: agencies.map { |a|
        snaps = a.agency_snapshots.sort_by(&:snapshot_date)
        latest = snaps.last
        oldest = snaps.first
        prev = snaps[-2]

        growth_rate = if oldest && latest && oldest != latest && oldest.word_count > 0
          ((latest.word_count - oldest.word_count).to_f / oldest.word_count * 100).round(2)
        end

        delta = latest && prev ? (latest.word_count - prev.word_count) : nil

        {
          id: a.id,
          name: a.name,
          slug: a.slug,
          latest_snapshot_date: latest&.snapshot_date,
          word_count: latest&.word_count,
          section_count: latest&.section_count,
          checksum_sha256: latest&.checksum_sha256,
          change_from_previous: delta,
          growth_rate_pct: growth_rate,
          snapshot_count: snaps.size,
          metrics: latest&.parsed_metrics || {}
        }
      }
    end

    def show
      agency = Agency.find(params[:id])
      snapshots = agency.agency_snapshots.order(snapshot_date: :asc)

      # Calculate overall growth
      if snapshots.size >= 2
        oldest = snapshots.first
        latest = snapshots.last
        total_growth = latest.word_count - oldest.word_count
        growth_rate = oldest.word_count > 0 ? ((total_growth.to_f / oldest.word_count) * 100).round(2) : 0
        days_tracked = (latest.snapshot_date - oldest.snapshot_date).to_i
      end

      render json: {
        id: agency.id,
        name: agency.name,
        slug: agency.slug,
        snapshot_count: snapshots.size,
        total_growth_words: total_growth,
        growth_rate_pct: growth_rate,
        days_tracked: days_tracked,
        snapshots: snapshots.each_with_index.map { |s, i|
          prev = i > 0 ? snapshots[i - 1] : nil
          delta = prev ? s.word_count - prev.word_count : nil
          pct_change = prev && prev.word_count > 0 ? (((s.word_count - prev.word_count).to_f / prev.word_count) * 100).round(2) : nil

          {
            snapshot_date: s.snapshot_date,
            word_count: s.word_count,
            section_count: s.section_count,
            checksum_sha256: s.checksum_sha256,
            change_from_previous: delta,
            pct_change: pct_change,
            metrics: s.parsed_metrics
          }
        }
      }
    end
  end
end
