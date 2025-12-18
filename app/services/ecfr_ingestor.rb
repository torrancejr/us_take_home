# frozen_string_literal: true

require "httparty"
require "digest"

class EcfrIngestor
  BASE_URL = "https://www.ecfr.gov/api".freeze
  ADMIN_BASE = "#{BASE_URL}/admin/v1".freeze
  VERSIONER_BASE = "#{BASE_URL}/versioner/v1".freeze

  # Industry keywords for targeting analysis (NAICS-aligned)
  INDUSTRY_KEYWORDS = {
    healthcare: {
      name: "Healthcare",
      keywords: %w[health medical hospital patient physician drug pharmaceutical medicine clinical healthcare nursing therapy treatment disease vaccine FDA],
      color: "rose",
      icon: "health"
    },
    finance: {
      name: "Finance",
      keywords: %w[bank banking financial credit loan mortgage insurance investment securities broker dealer lending interest rate treasury fiscal monetary],
      color: "emerald",
      icon: "finance"
    },
    energy: {
      name: "Energy",
      keywords: %w[energy oil gas petroleum nuclear electric utility pipeline fuel coal power renewable solar wind grid emission carbon],
      color: "amber",
      icon: "energy"
    },
    manufacturing: {
      name: "Manufacturing",
      keywords: %w[manufacturing factory industrial production plant equipment machinery assembly fabrication processing facility warehouse],
      color: "blue",
      icon: "manufacturing"
    },
    technology: {
      name: "Technology",
      keywords: %w[technology software computer digital electronic data cyber internet network telecommunications wireless broadband spectrum communication],
      color: "violet",
      icon: "technology"
    },
    agriculture: {
      name: "Agriculture",
      keywords: %w[agriculture farm crop livestock animal food grain dairy meat poultry pesticide fertilizer organic USDA agricultural],
      color: "lime",
      icon: "agriculture"
    },
    transportation: {
      name: "Transportation",
      keywords: %w[transportation vehicle motor carrier freight shipping rail railroad aviation aircraft airline airport highway road traffic safety DOT],
      color: "cyan",
      icon: "transportation"
    },
    construction: {
      name: "Construction",
      keywords: %w[construction building housing real estate property contractor architect engineer zoning permit land development residential commercial],
      color: "orange",
      icon: "construction"
    },
    environment: {
      name: "Environment",
      keywords: %w[environment environmental pollution emission waste hazardous contamination cleanup remediation air water soil EPA ecological conservation],
      color: "teal",
      icon: "environment"
    },
    labor: {
      name: "Labor",
      keywords: %w[labor worker employee employer wage salary overtime union workplace occupational safety OSHA employment hiring discrimination],
      color: "pink",
      icon: "labor"
    },
    defense: {
      name: "Defense",
      keywords: %w[defense military army navy marine air force weapon procurement contract security classified veteran armed forces DOD],
      color: "slate",
      icon: "defense"
    },
    education: {
      name: "Education",
      keywords: %w[education school student university college teacher academic curriculum grant loan financial aid institution learning training],
      color: "indigo",
      icon: "education"
    },
    small_business: {
      name: "Small Business",
      keywords: %w[small business entrepreneur startup minority women-owned disadvantaged SBA procurement contract set-aside size standard],
      color: "fuchsia",
      icon: "small_business"
    },
    trade: {
      name: "Trade",
      keywords: %w[trade import export tariff customs duty quota international commerce foreign border goods merchandise antidumping countervailing],
      color: "sky",
      icon: "trade"
    }
  }.freeze

  def initialize
    @titles_cache = {}
  end

  def ingest_all(snapshot_date: Date.current)
    api_date = format_date_for_api(snapshot_date)
    puts "  Using API date: #{api_date}"

    agencies = fetch_agencies
    count = 0
    total = agencies.size

    agencies.each_with_index do |agency_hash, idx|
      slug = agency_hash["slug"]
      puts "  [#{idx + 1}/#{total}] Processing: #{agency_hash['name']}"
      ingest_agency(agency_hash, snapshot_date: snapshot_date, api_date: api_date)
      count += 1
    rescue StandardError => e
      Rails.logger.error("Failed to ingest agency #{slug}: #{e.message}")
      puts "    ⚠ Error: #{e.message}"
    end

    count
  end

  def ingest_agency(agency_hash, snapshot_date: Date.current, api_date: nil)
    api_date ||= format_date_for_api(snapshot_date)
    slug = agency_hash.fetch("slug")
    name = agency_hash.fetch("name")

    agency = Agency.find_or_create_by!(slug: slug) { |a| a.name = name }
    agency.update!(name: name) if agency.name != name

    # Fetch metrics for the agency based on their CFR references
    cfr_refs = agency_hash["cfr_references"] || []
    metrics_data = calculate_agency_metrics(cfr_refs, api_date)

    AgencySnapshot.upsert(
      {
        agency_id: agency.id,
        snapshot_date: snapshot_date,
        word_count: metrics_data[:word_count],
        section_count: metrics_data[:section_count],
        checksum_sha256: metrics_data[:checksum],
        metrics_json: metrics_data[:metrics].to_json,
        created_at: Time.current,
        updated_at: Time.current
      },
      unique_by: [:agency_id, :snapshot_date]
    )

    true
  end

  private

  def format_date_for_api(date)
    date.strftime("%Y-%m-%d")
  end

  def fetch_agencies
    res = HTTParty.get("#{ADMIN_BASE}/agencies.json", headers: api_headers, format: :json, timeout: 30)
    raise "Failed agencies fetch: #{res.code}" unless res.code == 200

    res.parsed_response["agencies"] || []
  end

  def calculate_agency_metrics(cfr_refs, api_date)
    total_size = 0
    total_sections = 0
    combined_text = +""

    cfr_refs.each do |ref|
      title_num = ref["title"]
      chapter = ref["chapter"]
      next unless title_num

      structure = fetch_title_structure(title_num, api_date)
      next unless structure

      chapter_data = find_chapter(structure, chapter)
      data_to_process = chapter_data || structure

      size, sections, text = extract_metrics_from_structure(data_to_process)
      total_size += size
      total_sections += sections
      combined_text << " " << text
    end

    word_count = (total_size / 5.5).round
    normalized = normalize_text(combined_text)

    # Calculate industry targeting scores
    industry_scores = calculate_industry_scores(normalized, word_count)

    checksum_input = "#{total_size}:#{total_sections}:#{normalized}"
    checksum = Digest::SHA256.hexdigest(checksum_input)

    {
      word_count: word_count,
      section_count: total_sections,
      checksum: checksum,
      metrics: {
        total_size_bytes: total_size,
        api_date_used: api_date,
        industry_scores: industry_scores
      }
    }
  end

  def calculate_industry_scores(text, word_count)
    return {} if text.empty? || word_count == 0

    text_lower = text.downcase
    scores = {}

    INDUSTRY_KEYWORDS.each do |key, config|
      # Count keyword matches
      matches = config[:keywords].sum do |keyword|
        text_lower.scan(/\b#{Regexp.escape(keyword.downcase)}\b/i).length
      end

      # Normalize to per 10,000 words for comparability
      score = ((matches.to_f / word_count) * 10_000).round(1)

      scores[key.to_s] = {
        name: config[:name],
        score: score,
        matches: matches,
        color: config[:color]
      }
    end

    # Sort by score descending and return top industries
    scores.sort_by { |_k, v| -v[:score] }.to_h
  end

  def fetch_title_structure(title_num, api_date)
    cache_key = "#{title_num}_#{api_date}"
    return @titles_cache[cache_key] if @titles_cache.key?(cache_key)

    url = "#{VERSIONER_BASE}/structure/#{api_date}/title-#{title_num}.json"
    res = HTTParty.get(url, headers: api_headers, format: :json, timeout: 60)

    if res.code == 200 && res.parsed_response.is_a?(Hash) && !res.parsed_response.key?("error")
      @titles_cache[cache_key] = res.parsed_response
      return res.parsed_response
    end

    if res.parsed_response.is_a?(Hash) && res.parsed_response["error"]
      Rails.logger.warn("API error for title #{title_num} on #{api_date}: #{res.parsed_response['error']}")
    end

    @titles_cache[cache_key] = nil
    nil
  rescue StandardError => e
    Rails.logger.warn("Could not fetch title #{title_num} for #{api_date}: #{e.message}")
    @titles_cache[cache_key] = nil
    nil
  end

  def find_chapter(structure, chapter_id)
    return nil unless structure && chapter_id

    children = structure["children"] || []
    children.find { |c| c["type"] == "chapter" && c["identifier"] == chapter_id }
  end

  def extract_metrics_from_structure(data, depth = 0)
    return [0, 0, ""] if data.nil? || depth > 15

    size = data["size"] || 0
    sections = 0
    text = +""

    sections += 1 if data["type"] == "section" || data["type"] == "appendix"

    text << " #{data['label']}" if data["label"]
    text << " #{data['label_description']}" if data["label_description"]

    children = data["children"] || []
    children.each do |child|
      _child_size, child_sections, child_text = extract_metrics_from_structure(child, depth + 1)
      sections += child_sections
      text << child_text
    end

    [size, sections, text]
  end

  def normalize_text(text)
    text.to_s.gsub(/\s+/, " ").strip
  end

  def api_headers
    { "Accept" => "application/json" }
  end
end
