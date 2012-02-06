class SupplierViewController < ApplicationController
  layout "standard"
  before_filter :login_required, :dyna_connect
  filter_access_to :all

   def as_supplier
     
     @events = Event.with_invitee(current_user)
     open_evt = @events.reject {|e| ! e.status_open? }
     closed_evt = @events.reject {|e| ! e.status_closed? }
     @events = open_evt + closed_evt
     
     respond_to do |format|
        format.html
        format.xml  {  }
     end
   end

end
