class ReportsController < ApplicationController
  layout "standard"
  before_filter :login_required, :dyna_connect

  def global_activity
    
    # sorting setup
    order_string = ! params[:sort_by].nil? ?
                   "#{AuditRecord::SORT_COLS[params[:sort_by].to_i]} #{params[:sort_type].upcase}" : nil
    if order_string.nil?
      order_string = AuditRecord::SORT_COLS[3] + " DESC"
    end
    
    @audit_records = AuditRecord.paginate_by_sql(AuditRecord::GLOBAL_ACTIVITY_SQL + order_string,
                         :page => params[:page])
    
    respond_to do |format|
      format.html # global_activity.html.erb
    end
  end  
  
end
