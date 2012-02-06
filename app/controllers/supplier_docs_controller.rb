class SupplierDocsController < ApplicationController
  
  layout "standard"
  before_filter :login_required #, :only => [ :edit, :update ]
  filter_resource_access
  
  # GET /supplier_docs
  # GET /supplier_docs.xml
  def index
    @supplier_docs = SupplierDoc.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @supplier_docs }
    end
  end

  # GET /supplier_docs/1
  # GET /supplier_docs/1.xml
  def show
    @supplier_doc = SupplierDoc.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @supplier_doc }
    end
  end

  # GET /supplier_docs/new
  # GET /supplier_docs/new.xml
  def new
    @supplier_doc = SupplierDoc.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @supplier_doc }
    end
  end

  # GET /supplier_docs/1/edit
  def edit
    @supplier_doc = SupplierDoc.find(params[:id])
  end

  # POST /supplier_docs
  # POST /supplier_docs.xml
  def create
    @supplier_doc = SupplierDoc.new(params[:role])

    respond_to do |format|
      if @supplier_doc.save
        flash[:notice] = 'SupplierDoc was successfully created.'
        format.html { redirect_to(@supplier_doc) }
        format.xml  { render :xml => @supplier_doc, :status => :created, :location => @supplier_doc }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @supplier_doc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /supplier_docs/1
  # PUT /supplier_docs/1.xml
  def update
    @supplier_doc = SupplierDoc.find(params[:id])

    respond_to do |format|
      if @supplier_doc.update_attributes(params[:role])
        flash[:notice] = 'SupplierDoc was successfully updated.'
        format.html { redirect_to(@supplier_doc) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @supplier_doc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /supplier_docs/1
  # DELETE /supplier_docs/1.xml
  def destroy
    
    @supplier_doc = SupplierDoc.find_by_id(params[:id])
    @supplier_doc.destroy

    respond_to do |format|
      format.js
    end
  end
end
