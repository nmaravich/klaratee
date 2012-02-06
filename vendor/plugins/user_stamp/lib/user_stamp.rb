module UserStamp
  mattr_accessor :creator_attribute
  mattr_accessor :updater_attribute
  mattr_accessor :current_user_method
  
  def self.creator_assignment_method
    "#{UserStamp.creator_attribute}="
  end
  
  def self.updater_assignment_method
    "#{UserStamp.updater_attribute}="
  end
  
  module ClassMethods
    def user_stamp(*models)
      models.each { |klass| klass.add_observer(UserStampSweeper.instance) }
      
      class_eval do
        cache_sweeper :user_stamp_sweeper
      end
     end
  end
  

# These ruby-fu extensions provide the user_stampable (and thus the associations creator and updater) in ActivoRecord -- afuqua
  module ActiveRecordExt
    def self.included(base) #:nodoc:
        super
        base.extend(ClassMethods)
    end

    module ClassMethods
       def user_stampable(options = {})
          defaults  = {
                        :stamper_class_name => :aux_user,
                        :creator_attribute  => :creator_id,
                        :updater_attribute  => :updater_id,
                      }.merge(options)

          class_eval do
            belongs_to :creator, :class_name => defaults[:stamper_class_name].to_sym.to_s.singularize.camelize,
                                 :foreign_key => defaults[:creator_attribute]
                                 
            belongs_to :updater, :class_name => defaults[:stamper_class_name].to_sym.to_s.singularize.camelize,
                                 :foreign_key => defaults[:updater_attribute]
          end
      end
    end
  end
end # UserStamp module

ActiveRecord::Base.send(:include, UserStamp::ActiveRecordExt) if defined?(ActiveRecord)

UserStamp.creator_attribute   = :creator_id
UserStamp.updater_attribute   = :updater_id
UserStamp.current_user_method = :current_user

class UserStampSweeper < ActionController::Caching::Sweeper
  def before_validation(record)
    return unless current_user
    
    if record.respond_to?(UserStamp.creator_assignment_method) && record.new_record?
      record.send(UserStamp.creator_assignment_method, current_user.id)
    end
    
    if record.respond_to?(UserStamp.updater_assignment_method)
      record.send(UserStamp.updater_assignment_method, current_user.id)
    end
  end
  
  private  
    def current_user
      if controller.respond_to?(UserStamp.current_user_method)
        controller.send UserStamp.current_user_method
      end
    end
end