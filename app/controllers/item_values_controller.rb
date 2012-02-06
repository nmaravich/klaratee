class ItemValuesController < ApplicationController

  before_filter :login_required
  filter_resource_access

  # GET /item_values
  # GET /item_values.xml
  def index
    @item_values = ItemValue.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @item_values }
    end
  end

  # GET /item_values/1
  # GET /item_values/1.xml
  def show
    @item_value = ItemValue.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @item_value }
    end
  end

  # GET /item_values/new
  # GET /item_values/new.xml
  def new
    @item_value = ItemValue.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @item_value }
    end
  end

  # GET /item_values/1/edit
  def edit
    @item_value = ItemValue.find(params[:id])
  end

  # POST /item_values
  # POST /item_values.xml
  def create
    @item_value = ItemValue.new(params[:item_value])

    respond_to do |format|
      if @item_value.save
        flash[:notice] = 'ItemValue was successfully created.'
        format.html { redirect_to(@item_value) }
        format.xml  { render :xml => @item_value, :status => :created, :location => @item_value }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @item_value.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /item_values/1
  # PUT /item_values/1.xml
  def update
    @item_value = ItemValue.find(params[:id])

    respond_to do |format|
      if @item_value.update_attributes(params[:item_value])
        flash[:notice] = 'ItemValue was successfully updated.'
        format.html { redirect_to(@item_value) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @item_value.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /item_values/1
  # DELETE /item_values/1.xml
  def destroy
    @item_value = ItemValue.find(params[:id])
    @item_value.destroy

    respond_to do |format|
      format.html { redirect_to(item_values_url) }
      format.xml  { head :ok }
    end
  end
end
