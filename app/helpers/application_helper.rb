module ApplicationHelper
  def user_signed_in?
    Current.user.present?
  end

  def active_nav?(controller_name_sym)
    controller_name.to_sym == controller_name_sym
  end
end
