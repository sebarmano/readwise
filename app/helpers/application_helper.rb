module ApplicationHelper
  def user_signed_in?
    Current.user.present?
  end

  def active_nav?(controller_name_sym)
    controller_name.to_sym == controller_name_sym
  end

  def match_bar_class(score)
    return "none" if score.nil?
    if score >= 0.75
      "green"
    else
      (score >= 0.5) ? "amber" : "red"
    end
  end

  def taste_match_label(score)
    return "Not enough shared reads yet" if score.nil?
    if score >= 0.75
      "Great match"
    elsif score >= 0.5
      "Good match"
    else
      "Different tastes"
    end
  end
end
