
class FacebookPublisher < Facebooker::Rails::Publisher
  
  # BEGIN send_email
  def send_email(from,to, title, text, html)
    send_as :email
    recipients(to)
    from(from)
    title(title)
    fbml(html)
    text(text)
  end
  # END send_email
end