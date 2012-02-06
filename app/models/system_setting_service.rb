class SystemSettingService

  def self.get_value_for_key(key, company_id)
    setting = SystemSetting.find_by_company_id_and_key(company_id, key)
    if setting != nil
      return setting.value
    else
      setting = SystemSetting.find_by_company_id_and_key(0, key)
      return setting != nil ? setting.value : nil
    end
  end
end
