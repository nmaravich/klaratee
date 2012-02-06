class Authorization::Attribute
  protected
    def object_attribute_value (object, attr)
#      begin
        # afuqua's monkey patch to access hashes in authorization.rb
        puts "#{object.to_json} a:#{attr}"
        if object.is_a?(Hash)
          object[attr]
        else
          object.send(attr)
        end
#      rescue ArgumentError, NoMethodError => e
#        raise AuthorizationUsageError, "Error occurred while validating attribute ##{attr} on #{object.inspect}: #{e}.\n" +
#          "Please check your authorization rules and ensure the attribute is correctly spelled and \n" +
#          "corresponds to a method on the model you are authorizing for."
#      end
    end
end