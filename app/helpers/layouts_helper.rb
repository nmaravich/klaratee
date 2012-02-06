module LayoutsHelper
  
 def self.logo_path(company_name, logo_file)
    candidate_filename = "#{Rails.root}/public/images/logos/#{company_name}#{logo_file}"    
    if File.exists? candidate_filename
      return "logos/#{company_name}#{logo_file}"
    else
      return "logos/default#{logo_file}"
    end
 end

end
