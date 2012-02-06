class SupplierNotesController < ApplicationController

  before_filter :login_required
  
  filter_resource_access
  
  def create

    @supplier_note = SupplierNote.new(params[:supplier_note])
    
    flash[:notice] = "Created supplier note"
    respond_to do |format|
      if @supplier_note.save
        @supplier_notes = SupplierNote.find_all_by_supplier_id(params[:supplier_note][:supplier_id])  
        format.js
      end
    end
  end
  
def new
  
  @supplier_note = SupplierNote.new
  
  respond_to do |format|
    format.html # new.html.erb
    format.xml  { render :xml => @supplier_note }
  end

end

  # DELETE /supplier_notes/1
  def destroy
    
    @supplier_note = SupplierNote.find(params[:id])
    @supplier_note.destroy
    
    respond_to do |format|
      format.js
    end
  end  
  
end