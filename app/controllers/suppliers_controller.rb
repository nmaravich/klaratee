# For steaming the upload file
require "stringio"

class SuppliersController < ApplicationController
  
  layout 'standard'
  before_filter :login_required , :dyna_connect    
  filter_resource_access :additional_member => [:add_document, :remove_contact_from_supplier],
                         :additional_collection => [:download_document]
  
  # GET /suppliers
  # GET /suppliers.xml
  def index
    
    # sorting setup
    order_string = ! params[:sort_by].nil? ?
                   "#{Supplier::SORT_COLS[params[:sort_by].to_i]} #{params[:sort_type].upcase}" : nil
    if order_string.nil?
      order_string = Supplier::SORT_COLS[0] + " ASC"
    end
    
    @suppliers = Supplier.paginate :page => params[:page], :order => order_string
    
    respond_to do |format|
      format.html # index.html.erb
    end
    
  end
  
  # GET /suppliers/new
  # GET /suppliers/new.xml
  def new
    @supplier = Supplier.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @supplier }
    end
  end
  
  # GET /suppliers/1/edit
  def edit
    @supplier = Supplier.find(params[:id])
  end
  
  # POST /suppliers
  # POST /suppliers.xml
  def create
    @supplier = Supplier.new(params[:supplier])
    
    respond_to do |format|
      if @supplier.save
        flash.now[:notice] = 'Supplier was successfully created.'
        format.html { redirect_to(suppliers_path) }
        format.xml  { render :xml => @supplier, :status => :created, :location => @supplier }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @supplier.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /suppliers/1
  # PUT /suppliers/1.xml
  def update
    @supplier = Supplier.find(params[:id])
    
    if @supplier.update_attributes(params[:supplier])
      respond_to do |format|
        flash.now[:notice] = 'Supplier Updated!'
        # The creation of contacts is AJAX.  format.js means call a file named update.js.rjs and do what it says.
        format.js
      end    
    end
    
  end
  
  def destroy
    @supplier = Supplier.find(params[:id])
    @supplier.destroy
    respond_to do |format|
      format.html { redirect_to(suppliers_url) }
      format.xml  { head :ok }
      format.json { render :json => @supplier }
    end
  end  
  
  def download_document
    @supplier_document = SupplierDoc.find(params[:id])    
    send_file(@supplier_document.public_filename, 
      :disposition => 'attachment',
      :encoding => 'utf8', 
      :type => @supplier_document.content_type,
      :filename => URI.encode(@supplier_document.filename)) 
  end
  
  def add_document
    @sd = SupplierDoc.new(params[:supplier_doc])
    @sd.save!
    # Find all the documents for the given suppliers
    @supplier_documents = SupplierDoc.find_all_by_supplier_id(params[:id])  
    
    respond_to do |format|
      # The creation of contacts is AJAX.  format.js means call a file named update.js.rjs and do what it says.
      format.js do
        responds_to_parent do
          render :update do |page|
            page.replace_html( "document_list", :partial => "supplier_documents", :collection => @supplier_documents )
            page.insert_html :top, "document_list", "<div class='flash_notice''> #{flash[:notice]} </div>"
          end
        end          
      end
    end    
    flash.now[:notice] = 'Document Added'
  end
  
  # DELETE suppliers/1/contact/1
  def remove_contact_from_supplier
    @supplier = Supplier.find(params[:id])
    contact_to_remove = @supplier.contacts.detect{ |contact| contact.id.to_s == params[:contact]}
    # Delete this contact which in turn will delete the contact_supplier entry and the link to contact_data_templates
    Contact.destroy(contact_to_remove)
    
    respond_to do |format|
      format.html { redirect_to :action => 'edit', :id => params[:id] }
      format.xml  { head :ok }
      format.json { render :json => contact_to_remove }
    end
  end
  
end
