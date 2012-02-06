class SystemSettingsController < ApplicationController
  layout "standard"
  before_filter :login_required, :dyna_connect

  def index
    comp_id = session[:cur_company].id
    
    @settings = SystemSetting.find_by_sql([SystemSetting::FIND_SQL, comp_id, comp_id])
    
    respond_to do |format|
      format.html # index.html.erb
    end    
  end
  
  def edit
    comp_id = session[:cur_company].id
    
    def_setting = SystemSetting.find(params[:id])
    
    comp_setting = SystemSetting.find_by_company_id_and_key(comp_id, def_setting.key)
    
    @setting = comp_setting != nil ? comp_setting : def_setting
    
    respond_to do |format|
      format.html # edit.html.erb
    end    
  end
  
  def update
    
    setting = SystemSetting.find(params[:id])
    
    if setting.company_id == 0
      # create new setting override record
      new_setting = SystemSetting.new
      new_setting.company_id = session[:cur_company].id
      new_setting.key = setting.key
      new_setting.value = params[:system_setting][:value]
      new_setting.save
    else
      setting.value = params[:system_setting][:value]
      setting.save
    end
    
    flash[:notice] = 'Setting updated.'
    
    respond_to do |format|
        format.html { redirect_to(system_settings_url) }
    end    
  end
  
end
