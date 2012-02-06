class SupplierDoc < ActiveRecord::Base
  
  belongs_to :supplier
  user_stampable
  
  has_attachment :storage => :file_system, 
                 :max_size => 500.megabytes,
                 :path_prefix => "uploads/#{table_name}"

  before_validation_on_create :make_filename_unique
  validates_uniqueness_of :filename
  
#  validates_as_attachment

  private
  def make_filename_unique
    
    re = /(.*)(\..*)/
    match_result = re.match self.filename
    if match_result
      # split the filename myfilename.ext in 2 pieces (e.g.  "myfilename" + ".ext")
      #     or as another example: myfilename.version.2.ext into "myfilename.version.2" + ".ext"
      file_base = match_result[1]
      file_ext = match_result[2]
    else
      # filename has no extension
      file_base = self.filename
      file_ext = ""
    end
    
    idx = 1
    while SupplierDoc.exists?(:filename=> self.filename) 
       self.filename = file_base + " - copy #{idx}" + file_ext
       idx += 1       
    end
   
  end
  

end