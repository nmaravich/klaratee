module UsersHelper
  
 def activate_surrogate(surrogate_child_id, surrogate_child)
     session[:surrogate_parent] = {:user_id => current_user.id, :login => current_user.login, :child_id => surrogate_child_id, 
                                   :return_path => request.referer}     
     session[:user] = surrogate_child_id     
     parent_login = session[:surrogate_parent][:login]
     login_from_session
     
     #clear any parent session information that may cause issues
     session.delete :selected_event
     
     flash[:notice] = "You (#{parent_login}) are now acting as a surrogate for #{surrogate_child.login}."
 end
 
 def surrogate_link(surrogate_child)    
    if acting_as_surrogate?
       # if currently acting as a surrogate, gray out the "link"
       return 'Surrogate'       
    else
       # if not currently acting as a surrogate
       #       - case A: desired surrogate child user exists, return the link
       #       - case B: desired surrogate child user account does not yet exist, return a grayed out 'Surrogate'
       return surrogate_child.nil? ? 'Surrogate' : link_to('Surrogate', surrogate_set_path({:child_id => surrogate_child.id}))
    end
 end
 
 def acting_as_surrogate?
   return ! session[:surrogate_parent].nil?
 end

end
