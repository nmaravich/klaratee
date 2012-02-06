class Admin::SettingsController < ApplicationController  
  layout 'standard'
  before_filter :login_required
  filter_access_to :all, :context => :admin_settings
  
  def index
    
    @settings = SystemSetting.find_by_sql([SystemSetting::FIND_GLOBAL_SQL, 0, 0])
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  def edit
    @setting = SystemSetting.find(params[:id])
    
    respond_to do |format|
      format.html # edit.html.erb
    end    
  end
  
  def update
    
    setting = SystemSetting.find(params[:id])
    
    if setting.value != params[:system_setting][:value]
      setting.value = params[:system_setting][:value]
      setting.save
    end
    
    flash[:notice] = 'Setting updated.'
    
    respond_to do |format|
        format.html { redirect_to('/admin/settings') }
    end    
  end
  
end
