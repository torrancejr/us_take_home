# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @agencies = Agency.includes(:agency_snapshots).order(:name).map do |a|
      snaps = a.agency_snapshots.sort_by(&:snapshot_date)
      latest = snaps[-1]
      oldest = snaps[0]
      prev = snaps[-2]

      # Calculate word count change
      delta = latest && prev ? (latest.word_count - prev.word_count) : nil

      # Calculate growth rate percentage
      growth_rate = calculate_growth_rate(oldest, latest)

      {
        agency: a,
        latest: latest,
        oldest: oldest,
        delta: delta,
        growth_rate: growth_rate,
        snapshot_count: snaps.size,
        metrics: latest&.parsed_metrics || {}
      }
    end

    @total_agencies = @agencies.size
    @total_word_count = @agencies.sum { |a| a[:latest]&.word_count || 0 }
    @latest_date = @agencies.filter_map { |a| a[:latest]&.snapshot_date }.max
    @oldest_date = @agencies.filter_map { |a| a[:oldest]&.snapshot_date }.min
  end

  def show
    @agency = Agency.find(params[:id])
    @snapshots = @agency.agency_snapshots.order(snapshot_date: :asc)

    if @snapshots.size >= 2
      oldest = @snapshots.first
      latest = @snapshots.last
      @total_growth = latest.word_count - oldest.word_count
      @growth_rate = oldest.word_count > 0 ? ((@total_growth.to_f / oldest.word_count) * 100).round(2) : 0
      @days_tracked = (latest.snapshot_date - oldest.snapshot_date).to_i
    end

    @chart_data = @snapshots.each_with_index.map do |s, i|
      prev = i > 0 ? @snapshots[i - 1] : nil
      pct_change = prev && prev.word_count > 0 ? (((s.word_count - prev.word_count).to_f / prev.word_count) * 100).round(2) : nil
      {
        date: s.snapshot_date.to_s,
        word_count: s.word_count,
        section_count: s.section_count,
        delta: prev ? s.word_count - prev.word_count : nil,
        pct_change: pct_change,
        growth_rate: s.parsed_metrics["growth_rate_pct"] || 0
      }
    end
  end

  def ingest
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : nil
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : nil

    if start_date.nil? && end_date.nil?
      redirect_to dashboard_path, alert: "Please select at least one date"
      return
    end

    dates = [ start_date, end_date ].compact.uniq.sort
    ingestor = EcfrIngestor.new

    dates.each { |date| ingestor.ingest_all(snapshot_date: date) }

    redirect_to dashboard_path, notice: "Ingested data for #{dates.map { |d| d.strftime('%b %d, %Y') }.join(' and ')}"
  rescue StandardError => e
    redirect_to dashboard_path, alert: "Error: #{e.message}"
  end

  # One-time seed endpoint for production (no shell access)
  def seed
    if AgencySnapshot.count > 0
      redirect_to dashboard_path, notice: "Data already exists (#{AgencySnapshot.count} snapshots)"
      return
    end

    ingestor = EcfrIngestor.new
    ingestor.ingest_all(snapshot_date: Date.parse("2024-12-15"))
    ingestor.ingest_all(snapshot_date: Date.parse("2025-12-15"))

    redirect_to dashboard_path, notice: "Seeded data for 2024-12-15 and 2025-12-15"
  rescue StandardError => e
    redirect_to dashboard_path, alert: "Seed error: #{e.message}"
  end

  private

  def calculate_growth_rate(oldest, latest)
    return nil unless oldest && latest && oldest != latest
    return nil if oldest.word_count == 0

    ((latest.word_count - oldest.word_count).to_f / oldest.word_count * 100).round(2)
  end
end
