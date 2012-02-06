class EventsSuppliersController < ApplicationController
  # GET /events_suppliers
  # GET /events_suppliers.xml
  
  before_filter :login_required
  
  filter_resource_access 
  
  def index
    @events_suppliers = EventsSupplier.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @events_suppliers }
    end
  end

  # GET /events_suppliers/1
  # GET /events_suppliers/1.xml
  def show
    @events_supplier = EventsSupplier.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @events_supplier }
    end
  end

  # GET /events_suppliers/new
  # GET /events_suppliers/new.xml
  def new
    @events_supplier = EventsSupplier.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @events_supplier }
    end
  end

  # GET /events_suppliers/1/edit
  def edit
    @events_supplier = EventsSupplier.find(params[:id])
  end

  # POST /events_suppliers
  # POST /events_suppliers.xml
  def create
    @events_supplier = EventsSupplier.new(params[:events_supplier])

    respond_to do |format|
      if @events_supplier.save
        flash[:notice] = 'EventsSupplier was successfully created.'
        format.html { redirect_to(@events_supplier) }
        format.xml  { render :xml => @events_supplier, :status => :created, :location => @events_supplier }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @events_supplier.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /events_suppliers/1
  # PUT /events_suppliers/1.xml
  def update
    @events_supplier = EventsSupplier.find(params[:id])

    respond_to do |format|
      if @events_supplier.update_attributes(params[:events_supplier])
        flash[:notice] = 'EventsSupplier was successfully updated.'
        format.html { redirect_to(@events_supplier) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @events_supplier.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /events_suppliers/1
  # DELETE /events_suppliers/1.xml
  def destroy
    @events_supplier = EventsSupplier.find(params[:id])
    @events_supplier.destroy

    respond_to do |format|
      format.html { redirect_to(events_suppliers_url) }
      format.xml  { head :ok }
    end
  end
end
