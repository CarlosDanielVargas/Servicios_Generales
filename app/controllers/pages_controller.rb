# frozen_string_literal: true

# PagesController is responsible for static pages in the application.
# Currently, it includes an action to render the home page.
class PagesController < ApplicationController
  # The home action renders the home page.
  # As there is no explicit render command within the method, Rails will
  # by convention render the view corresponding to the action - in this case,
  # the home view (home.html.erb).
  def home; end
end
