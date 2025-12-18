# frozen_string_literal: true

module IndustryHelper
  INDUSTRY_CONFIG = {
    "healthcare" => { name: "Healthcare", color: "rose", emoji: "🏥" },
    "finance" => { name: "Finance", color: "emerald", emoji: "🏦" },
    "energy" => { name: "Energy", color: "amber", emoji: "⚡" },
    "manufacturing" => { name: "Manufacturing", color: "blue", emoji: "🏭" },
    "technology" => { name: "Technology", color: "violet", emoji: "💻" },
    "agriculture" => { name: "Agriculture", color: "lime", emoji: "🌾" },
    "transportation" => { name: "Transportation", color: "cyan", emoji: "🚛" },
    "construction" => { name: "Construction", color: "orange", emoji: "🏗️" },
    "environment" => { name: "Environment", color: "teal", emoji: "🌿" },
    "labor" => { name: "Labor", color: "pink", emoji: "👷" },
    "defense" => { name: "Defense", color: "slate", emoji: "🛡️" },
    "education" => { name: "Education", color: "indigo", emoji: "🎓" },
    "small_business" => { name: "Small Business", color: "fuchsia", emoji: "🏪" },
    "trade" => { name: "Trade", color: "sky", emoji: "🌐" }
  }.freeze

  def industry_badge(key, score, size: :sm)
    config = INDUSTRY_CONFIG[key.to_s] || { name: key.to_s.titleize, color: "gray", emoji: "📊" }

    color_classes = case config[:color]
    when "rose" then "bg-rose-500/20 text-rose-400 border-rose-500/30"
    when "emerald" then "bg-emerald-500/20 text-emerald-400 border-emerald-500/30"
    when "amber" then "bg-amber-500/20 text-amber-400 border-amber-500/30"
    when "blue" then "bg-blue-500/20 text-blue-400 border-blue-500/30"
    when "violet" then "bg-violet-500/20 text-violet-400 border-violet-500/30"
    when "lime" then "bg-lime-500/20 text-lime-400 border-lime-500/30"
    when "cyan" then "bg-cyan-500/20 text-cyan-400 border-cyan-500/30"
    when "orange" then "bg-orange-500/20 text-orange-400 border-orange-500/30"
    when "teal" then "bg-teal-500/20 text-teal-400 border-teal-500/30"
    when "pink" then "bg-pink-500/20 text-pink-400 border-pink-500/30"
    when "slate" then "bg-slate-500/20 text-slate-400 border-slate-500/30"
    when "indigo" then "bg-indigo-500/20 text-indigo-400 border-indigo-500/30"
    when "fuchsia" then "bg-fuchsia-500/20 text-fuchsia-400 border-fuchsia-500/30"
    when "sky" then "bg-sky-500/20 text-sky-400 border-sky-500/30"
    else "bg-gray-500/20 text-gray-400 border-gray-500/30"
    end

    size_classes = case size
    when :xs then "text-xs px-1.5 py-0.5"
    when :sm then "text-xs px-2 py-1"
    when :md then "text-sm px-2.5 py-1"
    else "text-xs px-2 py-1"
    end

    content_tag(:span, class: "inline-flex items-center gap-1 rounded-lg border #{color_classes} #{size_classes}") do
      "#{config[:emoji]} #{config[:name]} #{score}".html_safe
    end
  end

  def top_industries(industry_scores, limit: 3)
    return [] unless industry_scores.is_a?(Hash)

    industry_scores
      .select { |_k, v| v.is_a?(Hash) && v["score"].to_f > 0 }
      .sort_by { |_k, v| -v["score"].to_f }
      .first(limit)
  end

  def industry_bar(key, score, max_score)
    config = INDUSTRY_CONFIG[key.to_s] || { name: key.to_s.titleize, color: "gray", emoji: "📊" }
    percentage = max_score > 0 ? [(score.to_f / max_score * 100), 100].min : 0

    bg_class = case config[:color]
    when "rose" then "bg-rose-500"
    when "emerald" then "bg-emerald-500"
    when "amber" then "bg-amber-500"
    when "blue" then "bg-blue-500"
    when "violet" then "bg-violet-500"
    when "lime" then "bg-lime-500"
    when "cyan" then "bg-cyan-500"
    when "orange" then "bg-orange-500"
    when "teal" then "bg-teal-500"
    when "pink" then "bg-pink-500"
    when "slate" then "bg-slate-500"
    when "indigo" then "bg-indigo-500"
    when "fuchsia" then "bg-fuchsia-500"
    when "sky" then "bg-sky-500"
    else "bg-gray-500"
    end

    { config: config, percentage: percentage, bg_class: bg_class }
  end
end

