module UsersHelper
  def format_user_phone(phone)
    phone || empty_cell_contents
  end

  def empty_cell_contents
    content_tag('span', '(none)', class: 'muted')
  end

  def update_user_path(user, params = {})
    url_for({ controller: "users", action: "update", id: user.id }.merge(params))
  end
end
