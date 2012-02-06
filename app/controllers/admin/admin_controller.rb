class Admin::AdminController < ApplicationController  
  layout 'standard'
  before_filter :login_required
  filter_access_to :all, :context => :admin
  
  def index
    respond_to do |format|
      format.html # index.html.erb
    end    
  end
end
