class FaqsController < ApplicationController
  
  include FaqsHelper
  layout "standard"
  filter_access_to [:update, :edit, :new, :destroy, :show], :attribute_check => true, :load_method => :load_faq_b
  
  filter_access_to :index, :attribute_check => true, :load_method => :make_index_object 
  filter_access_to [:new, :create], :attribute_check => true, :load_method => :make_new_object

  def make_new_object
     return if (has_role?(Role::BUYER.to_sym) || has_role?(Role::ADMIN.to_sym))  
     @obj = {}
     @obj[:can_create_faq] = current_aux_user.invited_to_event?(Faq.find_by_id(params[:faq][:parent_id].to_i).event_id)
     @obj
  end
  protected :make_new_object
  
  def load_faq_b    
    return if (has_role?(Role::BUYER.to_sym) || has_role?(Role::ADMIN.to_sym))  
    @obj = {}    
    if params[:action] == "edit" and params[:id] == "null"      
      # allow access to a blank edit form
      @obj[:can_get_blank_form] = true
      @obj[:can_update_faq] = false
    else
      @faq = Faq.find_by_id(params[:id])
      event_id = @faq.event_id    
      @obj[:can_read_faq] = current_aux_user.invited_to_event?(event_id)
      @obj[:can_update_faq] = @faq.user_id == current_user.id
    end
  
    logger.info @obj.to_json
    @obj
  end
  protected :load_faq_b
  
  def make_index_object
    return if (has_role?(Role::BUYER.to_sym) || has_role?(Role::ADMIN.to_sym))  
    @obj = {}
    
    event_id = params[:event]
    faq_id = params[:id]
    if ! faq_id.nil? 
       event_id = Faq.find_by_id(faq_id).event_id
    end
    
    @obj[:can_read_faq] = current_aux_user.invited_to_event?(event_id)
    @obj
  end
  protected :make_index_object
  
  def index
    @root_faq = Faq.find(:first, :conditions => {:family_id => params[:event]})
    @event = Event.find_by_id(params[:event])
    @faqs = @root_faq.nil? ? nil : faqs_for_user(@root_faq.children.first)
  end

  def create
    @faq = Faq.new(params[:faq].merge({:user_id=>current_user.id}))
        
    if @faq.save           
      render :update do |page|                          
          update_faq_table_and_replies(page)
      end
    end
  end

  def update
    @faq = Faq.find(params[:id])          
    if @faq.update_attributes(params[:faq])
        render :update do |page|                                      
             update_faq_table_and_replies(page)             
        end      
    end
  end

  def destroy
    @faq = Faq.find(params[:id])   
    @faq.destroy
    
    respond_to do |format|
      format.html { redirect_to(events_url) }
      format.xml  { head :ok }
      format.json { render :update do |page|
                       update_faq_table_and_replies(page)
                    end
                    }
     end
  end

  def new
  end

  def edit    
    parent_id = (params[:parent_id] == "null") ? nil : params[:parent_id]
    
    @faq = nil
    if params[:id] != "null" 
      @faq = Faq.find(params[:id])
      textarea_title = 'Edit FAQ'
    else
      @parent = Faq.find_by_id(parent_id)
      if @parent.level == 0
        textarea_title = 'Add new FAQ'
      else                
        textarea_title = 'Reply to FAQ'
      end
    end
    
    render :update do |page|                          
        page << "$('#faq-form').replaceWith('" + escape_javascript(render(:partial => "faq_form", :locals => { :faq => @faq, :textarea_title => textarea_title, :parent_id => parent_id })) +"');" 
    end      
  end

  def show
    @faq = Faq.find_by_id(params[:id])
    @parent = @faq.parent
    @children = @faq.children
    @replies = faqs_for_user(@faq.children.first)
  end

end
