// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


/* ----------  GENERIC ---------- */
/*
 * These are utility methods that can be used anywhere.
 * Other methods in here may be specific to a particular page.
 */

/*
 * Call this when you want to display an ajax message on the screen.
 * It expects the string containing the message and the type of 
 * message.
 * 
 * Possible types are: [warn, notice, error
 */
function ajax_message_handler(msg, msg_type){

    div_id = 'error-box'
    switch (msg_type) {
        case 'warn':
            div_id = 'warning-box'
            break;
        case 'notice':
		    div_id = 'notice-box'
            break;
    }
    
    // Ensures messages don't pile up in cases where you do multiple updates for example.
	$("#error-box,#warning-box,#notice-box").remove();
	// Write the message box
    $("<div id=\"" +div_id + "\">" + msg + "</div>").prependTo($('#messages-container'));
}

/*
 * jQuery data picker helper.
 * params:
 *   id - The id of the element to bind the calendar to.
 *        When you actually select a date this is where it will go.
 */
function show_date_picker(id){
    $("#" + id).datepicker({
        showOn: 'button',
        buttonImage: 'images/calendar.gif',
        buttonImageOnly: true
    });
}

/*
 * Build table cells from the item(s) given
 * params:
 *   items - array of items to td-ify
 * returns:
 *   string of table cells. - <td>xxx</td><td>yyy</td>
 *
 */
function build_cells(items){
    var results = "";
    
    if (items instanceof Array) {
        jQuery.each(items, function(){
			if (this instanceof Array) {
				/* id the items array contains elements that are themselves an array, pass the element[1] to wrap 
				 * this is used to make sure newly created td elements have appropriate id's so edits will show up
				 * immediately */
				results += wrap(this[0], 'td', this[1]);
			} else {
				results += wrap(this, 'td')
			}
        });
    }
    else {
        // You should to call wrap if you have one item but I got your back if you forget.
        results += wrap(items, 'td');
    }
    
    return results;
}

/*
 * Wraps given text in the given tag.
 * params:
 *  text - the string you want to wrap
 *  tag  - the tag you want to wrap with no < or > included
 *  attr - allows for one tag attribute to be added. ( id or class or something )
 * returns:
 *  String containing the wrapped text.
 * usage:
 *   wrap('joe', 'hugs')
 *   result: <hugs>joe</hugs>
 *   wrap('joe', 'hugs', "class='love'"
 *   result: <hugs class='love'>joe</hugs>
 */
function wrap(text, tag, attr){
    attr = attr || "";
    return "<" + tag + " " + attr + ">" + text + "</" + tag + ">";
}

/*
 * Clears all the form values for the given form id.
 * params:
 *  form_id - the jquery style id of the form.
 * usage:
 *  clearForm($('#template-column-form'));
 *
 */
function clearForm(form_id){
    // iterate over all of the inputs for the form and reset them.
    $(':input', form_id).each(function(){
        var type = this.type;
        var tag = this.tagName.toLowerCase(); // normalize case
        if (type == 'text' || type == 'password' || tag == 'textarea') {
            this.value = "";
        }
        else {
            if (type == 'checkbox' || type == 'radio') {
                this.checked = false;
            }
            else {
                if (tag == 'select') 
                    this.selectedIndex = -1;
            }
        }
    });
};

// Prevents the mouse from highlighting any text on this element
function make_sortable(element_id){
    $('#' + element_id).sortable();
    $('#' + element_id).disableSelection();
}

// for manage contacts screen.
function mass_selector(){
    var toggle = false;
    if ($('#group_selector').attr('checked')) {
        toggle = true;
    }
    $('input[id^=contact_]').attr('checked', toggle);
}

/*
	A generic way to delete objects.  You can use to delete an event, supplier, etc.
	It presents a confirm modal window and makes an ajax call to delete the object.
	Note: Your controller needs to have an ajax ready destroy method.
	params: obj_id - The id of the object you want to delete
	        obj_name - The name of the model you would like to delete
	        heading - This is what will appear at the top of the modal window
*/
function generic_modal_confirm_delete(obj_id, obj_name, heading, height){
	  obj_name = obj_name.toLowerCase();
	
    if (heading == null) {
        heading = "Delete";
    }
	
	if(height == null) {
		height = 140;
	}
	
    $("#dialog-confirm").dialog({
        resizable: false,
        height: height,
        modal: true,
        title: heading || "Confirm Delete",
        buttons: {
            'No': function(){
                $(this).dialog('close');
            },
            'Yes': function(){
                $(this).dialog('close');
                $.ajax({
                    type: "DELETE",
                    url: "/"+obj_name+"s/"+obj_id,
                    data: {
                        '_method': 'delete',
                        'authenticity_token': token,
                        'format': 'json'
                    },
                    success: function(msg){
                        // Update screen by removing deleted object
                        $("#"+obj_name+"_id_"+obj_id).remove();
                        ajax_message_handler(obj_name +' deleted successfully', 'notice'); 
                    }
                });
            }
        }
    });
}

//loading popup with jQuery  
function showUploadPopup(){  
  //loads popup only if it is disabled  
  if(popupStatus==0){  
    $("#fadeInPopup").css({ "opacity": "0.7" });  
    $("#fadeInPopup").fadeIn("slow");  
    $("#uploadPopup").fadeIn("slow");  
    popupStatus = 1;  
  }  
}  

//centering popup  
function centerPopup(){
	//request data for centering  
	var windowWidth = document.documentElement.clientWidth;
	var windowHeight = document.documentElement.clientHeight;
	var popupHeight = $("#uploadPopup").height();
	var popupWidth = $("#uploadPopup").width();
	//centering  
	$("#uploadPopup").css({
		"position": "absolute",
		"top": windowHeight / 2 - popupHeight / 2,
		"left": windowWidth / 2 - popupWidth / 2
	});	
}  
/* ------------------------------ */

/* ---------- MANAGE TEMPLATE CONTACTS PAGE -------- */

/*
 * Confirmation of form submit using a jquery modal.
 * This isn't possible using all rails stuff.
 * params:
 *  form_id - The id of form you want to submit if the user answer's yes.
 *  confirm_msg - What do display in the modal. (i.e Are you sure? )
 */
function confirmation_modal(form_id, confirm_msg){
	
	$('#confirm-msg').html(confirm_msg);
	
    $("#dialog-confirm").dialog({
        resizable: true,
        height: 250,
        width: 375,
        modal: true,
        title: "Are you sure?",
        buttons: {
            'No': function(){
                $(this).dialog('close');
				result=false;
            },
            'Yes': function(){
                $(this).dialog('close');
				$("#"+form_id).trigger('onsubmit');
            }
        }
    });
}

/* ------------------------------ */

/* ---------- TEMPLATES PAGE -------- */

function remove_contact_from_template_modal(template_id, contact_id, heading){

    if (heading != null) {
        heading = "Deleting: " + heading;
    }
    
    $("#dialog-confirm").dialog({
        resizable: false,
        height: 140,
        modal: true,
        title: heading || "Confirm Delete",
        buttons: {
            'No': function(){
                $(this).dialog('close');
            },
            'Yes': function(){
                $(this).dialog('close');
                $.ajax({
                    type: "DELETE",
                    url: "/data_templates/" + template_id + "/contact/" + contact_id,
                    data: {
                        '_method': 'delete',
                        'authenticity_token': token,
                        'format': 'json'
                    },
                    success: function(msg){
                        // Update screen by removing the deleted contact(s)
                        $.each(msg, function(){
                            $.each(this, function(k, v){
                                $('#contact_id_' + this.id).remove();
                            });
                        });
						ajax_message_handler('Contact(s) successfully removed from data template.', 'notice');				
                    }
                });
            }
        }
    });
}

function template_column_confirm(template_id, template_col_id, heading) {

    if (heading != null) {
        heading = "Deleting: " + heading;
    }
    
    $("#dialog-confirm").dialog({
        resizable: false,
        height: 140,
        modal: true,
        title: heading || "Confirm Delete",
        buttons: {
            'No': function(){
                $(this).dialog('close');
            },
            'Yes': function(){
                $(this).dialog('close');
                $.ajax({
                    type: "DELETE",
                    url: "/data_templates/" + template_id + "/remove_template_column/" + template_col_id,
                    data: {
                        '_method': 'delete',
                        'authenticity_token': token,
                        'format': 'json'
                    },
                    success: function(msg){
						$('#col_' + template_col_id).remove();
                        ajax_message_handler('Template column deleted successfully', 'notice'); 
                    }
                });
            }
        }
    });
}

function save_template_column(template_column_id, close_modal){
    /* new_data_template_column is the name of the form containing the columns.
     * Its from template_column_dialog.html.erb
     */
	
	var niceColType = { 'string_value':'Text', 'text_value':'Large Text', 'int_value':'Numeric', 'decimal_value':'Decimal', 'select_one':'Select One', 'select_many':'Select Many' };
	
    if (template_column_id == null) {
        /* Create New */
        $.ajax({
            type: "POST",
            url: "/data_template_columns",
            data: $.param($("#new_data_template_column").serializeArray()) + '&amp;format=json',
			dataType: "json",
            success: function(msg){
                // Update the dom to show the changes
                box = "<li class='sorter' id='col_" + msg.data_template_column.id + "'>";
                // Top row ( handle image )
                box += "<div class='col-handle'>";
                box += "<img alt='draggable column' src='/images/template-col-handle.gif' />"
                box += "</div>";
                // Edit and delete images
                box += "<div class='action-group'>";
                box += "<a href='#' onclick=\"template_column_modal(" + msg.data_template_column.id + " , 'Edit Template Column', '" + msg.data_template_column.possible_vals + "' ); return false;\"><img title='Edit column' border='0' src='/images/template-col-edit.png' /></a> "
                box += "<a href=\"#\" onclick=\"template_column_confirm(" + msg.data_template_column.data_template_id + "," + msg.data_template_column.id +"); return false;\"><img title='Delete column' border='0' src='/images/template-col-delete.png' /></a>"
                box += "</div>"
                // Box attributes
                box += "<div class='col-attrs'><span id='col_name_" + msg.data_template_column.id + "' class='name'>";
                box += msg.data_template_column.name;
                box += "</span><br/><span id='col_type_" + msg.data_template_column.id + "' class='type' colType='" + msg.data_template_column.col_type + "'>";
                box += niceColType[msg.data_template_column.col_type];
                box += "</span><br/><span class='required'>";
                
                var req = 'Not Required'
                if (msg.data_template_column.required == 1) {
                    req = 'Required'
                }
                box += req
                box += "</span></div>"
                box += "</li>";
                
                if ($("#sortable li").length > 0) {
                    $('#sortable li:last').after(box);
                }
                else {
                    /* If its the first column the li:last won't be able to add the col */
                    $("#sortable").append(box);
                }
				ajax_message_handler('Data template column was successfully created.', 'notice');
            },
			error: function(xhr, status, error) {
			     ajax_message_handler(xhr.responseText, 'error'); 
		    }
        });
    }
    else {
        /* Edit Existing */
        $.ajax({
            type: "PUT",
            url: "/data_template_columns/" + template_column_id,
            data: $.param($("#new_data_template_column").serializeArray()) + '&format=json',
            success: function(msg){
				$("#col_name_" + msg.data_template_column.id).text(msg.data_template_column.name);
				$("#col_type_" + msg.data_template_column.id).attr('colType', msg.data_template_column.col_type);
	            $("#col_type_" + msg.data_template_column.id).text(niceColType[msg.data_template_column.col_type]);
				
                var req = 'Not Required'
                if (msg.data_template_column.required == 1) {
                    req = 'Required'
                }
				
	            $("#col_required_" + msg.data_template_column.id).text(req);
				ajax_message_handler('Data template column was successfully updated.', 'notice');
            },
            error: function(xhr, status, error) {
               ajax_message_handler(xhr.responseText, 'error'); 
            }
        });
    }
    
	// You may want to leave the modal around and add another one.
    if (close_modal) {
        $('#template-column-form').dialog('close');
    }
}

function template_column_modal(template_column_id, heading, possible_values){
    
    /* Prepopulating the form when editing */
    if (template_column_id != null) {
        $('#data_template_column_name').val($('#col_name_' + template_column_id).text());
        $('#data_template_column_col_type').val($('#col_type_' + template_column_id).attr('colType'));
        
        if (new RegExp("^Required$").test( $.trim($('#col_required_' + template_column_id).text()) ) ) {
            $('#data_template_column_required').attr('checked', true);
        }
        else {
            $('#data_template_column_required').attr('checked', false);
        }
        
        /* Ensure the possible values box appears if col_type is select_one or select_many */
        var val = $('#data_template_column_col_type').val();
        $("#multivalue").hide();
        if (val == 'select_one' || val == 'select_many') {
			$("#multivalue textarea").val(possible_values)
			$("#multivalue").show();
        }
    } else {
		// Need to do this clear or if you edit a column then add a column the previous values will stick.
        $('#data_template_column_name').val('');
        $('#data_template_column_col_type').val(1);
        $('#data_template_column_required').attr('checked', false);
	}
    
    $("#template-column-form").dialog({
        autoOpen: true,
        resizable: true,
        height: 370,
        width: 400,
        modal: true,
        title: heading || "Complete the Form",
        buttons: {
            'Save': function(){
                save_template_column(template_column_id, true);
            },
            'Save and Add': function(){
                save_template_column(template_column_id, false);
                clearForm($('#template-column-form'));
            },
            Cancel: function(){
                $(this).dialog('close');
            }
        }
    });
}

function template_modal(template_id, heading){

    $("#data-template-form").dialog({
        autoOpen: true,
        resizable: false,
        height: 300,
        width: 350,
        modal: true,
        title: heading || "Complete the Form",
        buttons: {
            'Save': function(){
                if (template_id == null) {
                    /* Create New */
                    $.ajax({
                        type: "POST",
                        url: "/data_templates",
                        data: $.param($("#new_data_template").serializeArray()) + '&amp;format=json',
                        success: function(msg){
                            // Update the dom to show the changes
                            var cells = [];
                            cells.push(msg.data_template.name);
                            cells.push(msg.data_template.description);
														cells.push("&nbsp;"); 
														cells.push("&nbsp;");
                            cells.push("<a href='/data_templates/" + msg.data_template.id + "/edit'>View</a>");
                            cells.push("\<a href\=\"#\" onclick\=\"generic_modal_confirm_delete("+msg.data_template.id+",'data_template','"+msg.data_template.name+"')\">Delete</a>");
                            var attr = "id=data_template_id_" + msg.data_template.id;
                            $('#template-list tr:last').after(wrap(build_cells(cells), 'tr', attr));
                            // close the modal
                            $('#data-template-form').dialog('close');
                            ajax_message_handler('Template was successfully created.', 'notice');
                        },
     		            error: function(xhr, status, error) {
                            $('#data-template-form').dialog('close');
                           ajax_message_handler(xhr.responseText, 'error'); 
                        }
                    });
                }
                else {
                    /* Edit Existing */
                    $.ajax({
                        type: "PUT",
                        url: "/data_templates/" + template_id,
                        data: $.param($("#edit_data_template_" + template_id).serializeArray()) + '&amp;format=json',
                        success: function(msg){
                            // Update the dom to show the changes
                            $("#template_name").text(msg.data_template.name);
                            $("#template_description").text(msg.data_template.description);
                            // close the modal                            
                            $('#data-template-form').dialog('close');
                            ajax_message_handler('Template was successfully updated.', 'notice');
                        },
                        error: function(xhr, status, error) {
                            $('#data-template-form').dialog('close');
                           ajax_message_handler(xhr.responseText, 'error'); 
                        }
                    });
                }
            },
            Cancel: function(){
                $(this).dialog('close');
            }
        }
    });
    /* Clear values */
    $("#data_template_name").val('');
    $("#data_template_description").val(''); 

}


/* ---------- FAQ PAGE ---------- */

function faq_modal(faq_id, heading, parent_id){

	$("#faq_text").val('');
	$("#faq_visibility").val('');
		
	/* populate the form */
	$.ajax({
		type: "GET",
	    async: false,
		url: "/faqs/" + faq_id + "/edit?parent_id=" + parent_id,
		success: function(a){				
		},
		error: function(a){				
		}
	});    
	
	
    $("#faq-form").dialog({
        autoOpen: true,
        resizable: false,
        height: 400,
        width: 500,
        modal: true,
        title: heading || "FAQ",
        buttons: {
            'Save': function(){
            
                if (faq_id == null) {
                    /* Create New */
                    $.ajax({
                        type: "POST",
                        url: "/faqs",
                        data: $.param($("#new_faq").serializeArray()),
                        success: function(msg){
    			             ajax_message_handler(heading + ' added.', 'notice');
                        },
                        error: function(xhr, status, error) {                            
                           ajax_message_handler(xhr.responseText, 'error'); 
                        }
                    });
					$('#faq-form').dialog('destroy');
                }
                else {
                    /* Edit Existing */
                    $.ajax({
                        type: "PUT",
                        url: "/faqs/" + faq_id,
                        data: $.param($("#edit_faq_"+faq_id).serializeArray()),
                        success: function(msg){                            
                             ajax_message_handler('FAQ successfully edited.', 'notice');							 							 
                        },
                        error: function(xhr, status, error) {
                             ajax_message_handler(xhr.responseText, 'error'); 
                        }
                    });
				    $('#faq-form').dialog('destroy');
                }
            },
            Cancel: function(){
                $(this).dialog('destroy');
            }
        }
    });
}

/* ---------------------------------- */

/* ---------- EVENTS PAGE ---------- */

function event_modal(event_id, heading){

    /* Clear anything that might be left over in these fields. */
    $("#event_name").attr('value', '');
    $("#event_start_date").attr('value', '');
    $("#event_end_date").attr('value', '');
	$("#event_status").attr('value', '');
    
    if (event_id != null) {
        $.getJSON('events/' + event_id, function(data){
            /* Prepopulate the form elements with the correct values before displaying the modal */
            $("#event_name").attr('value', data.event.name);
            $("#event_start_date").attr('value', data.event.start_date);
            $("#event_end_date").attr('value', data.event.end_date);
			$("#event_status").attr('value', data.event.status);
        });
    }
    else {
        /* Clear anything that might be left over in these fields. */
        $("#event_name").attr('value', '');
        $("#event_start_date").attr('value', '');
        $("#event_end_date").attr('value', '');
		$("#event_status").attr('value', '');
    }
    
    /* Build the date pickers. */
    show_date_picker('event_start_date');
    show_date_picker('event_end_date');
    
    $("#dialog-form").dialog({
        autoOpen: true,
        resizable: false,
        height: 300,
        width: 400,
        modal: true,
        title: heading || "Complete the Form",
        buttons: {
            'Save': function(){
            
                if (event_id == null) {
                    /* Create New */
                    $.ajax({
                        type: "POST",
                        url: "/events",
                        data: $.param($("#new_event").serializeArray()) + '&amp;format=json',
                        success: function(msg){
    			             ajax_message_handler('Event was successfully created.', 'notice');
                        },
                        error: function(xhr, status, error) {                            
                           ajax_message_handler(xhr.responseText, 'error'); 
                        }
                    });
					$('#dialog-form').dialog('close');
                }
                else {
                    /* Edit Existing */
                    $.ajax({
                        type: "PUT",
                        url: "/events/" + event_id,
                        data: $.param($("#new_event").serializeArray()) + '&amp;format=json',
                        success: function(msg){                            
                             ajax_message_handler('Event was successfully updated.', 'notice');							 							 
                        },
                        error: function(xhr, status, error) {
                             ajax_message_handler(xhr.responseText, 'error'); 
                        }
                    });
				    $('#dialog-form').dialog('close');
                }
            },
            Cancel: function(){
                $(this).dialog('close');
            }
        }
    });
}
/* --------------------------------- */

/* ---------- SUPPLIERS PAGE ---------- */
function inline_edit_contacts(obj, contact_info){
    // We need the supplier id for the url, and the contact id for the data.
    var contact_parts = contact_info.split("-");
    // Jeditable jquery plugin
    $('.edit').editable("/contacts/" + contact_parts[1], {
        submitdata: {
            attr: contact_parts[0],
            format: 'json'
        },
        method: 'PUT',
        tooltip: 'Click value to edit',
        onblur: 'submit',
		onerror : function(settings, original, xhr){
           ajax_message_handler(xhr.responseText, 'error'); 
        }
    });
}

function delete_supplier_contact_confirm(supplier_id, contact_id){
    $("#dialog-confirm").dialog({
        resizable: false,
        height: 140,
        modal: true,
        title: "Confirm Delete",
        buttons: {
            'No': function(){
                $(this).dialog('close');
            },
            'Yes': function(){
                $(this).dialog('close');
                $.ajax({
                    type: "DELETE",
                    url: "/suppliers/" + supplier_id + "/contact/" + contact_id,
                    data: {
                        '_method': 'delete',
                        'authenticity_token': token,
                        'format': 'json'
                    },
                    success: function(msg){
                        // Update screen by removing deleted contact
                        $('#contact_' + msg.contact.id).remove();
                    }
                });
            }
        }
    });
}
/* --------------------------------- */

/* ---------- ITEMS PAGE ---------- */

function inline_edit_items(obj, item_info){
    /* data_template_col-item is how this splits  */
    var item_parts = item_info.split("-");
    
    $('.edit').editable("/items/" + item_parts[1], {
        id: "column_id_item_id",
        submitdata: {
            col_id: item_parts[0],
            format: 'json'
        },
        method: 'PUT',
        tooltip: 'Click value to edit',
        onblur: 'submit',
        cssclass:'inline-edit'
//			style   : 'inherit'
        // something to think about later... this isn't valid just example
        // callback: function(value, settings) {
        //    $(this).highlightFade({ start: 'yellow', iterator: 'sinusoidal', speed: 3000 });
        // }
    });
}
/* --------------------------------- */

/* ---------- EVERY PAGE ---------- */

/*
 * Anything placed in here is fired when any page is loaded.
 * Be careful adding stuff here for performance sake.
 */
$(function(){
    // Ensure the content area is large enough to fit the content you are putting in there.
    adjust_page_height();
    // Ensure the correct tab state is displayed 
    tab_manager();
});


/* Auto-adjust page height of main content so longer pages don't poke through the bottom.*/
function adjust_page_height(){
    var pageHeight = $(document).height();
    /* Designed to expand for the items screen specifically! */
	var pageWidth = $('#items-list').width();
    $("div#main-content").css('height', pageHeight);

	width_key = 886;
	main_container_expander = 0;
	if(jQuery.support.cssFloat == false) {
        /* IE browsers need the the main_container to expand, non IE this happens automatically. */
		main_container_expander = 200;
	}
	
	if(pageWidth > width_key) {
     $("div#main-content").css('width', pageWidth);
     $("div#main-container").css('width', pageWidth + main_container_expander);
	}
}

/* Ensure the correct tab style is displayed for the page you are currently on. */
function tab_manager(){

    var pathname = window.location.pathname;
    var tab = '';
    
    
    if (pathname.match(/event/) || pathname.match(/faqs/) || pathname.match(/reports/) || pathname.match(/system_settings/)) {
        tab = 'event';
    }
    else 
        if (pathname.match(/template/)) {
            tab = 'template';
        }
        else 
            if (pathname.match(/supplierview/)) {
                tab = 'supplierview';
            }
            else 
                if (pathname.match(/supplier/) || pathname.match(/contacts/)) {
                    tab = 'supplier';
                }
                else 
                    if (pathname.match(/item/) || pathname.match(/upload/)) {
                        tab = 'item';
                    }
                    else 
                        if (pathname.match(/admin/)) {
                            tab = 'admin';
                        }
    
    $('#' + tab + '-tab').css('background', 'url("../../images/' + tab + 's_tab.gif")')
    $('#' + tab + '-tab div').css('color', '#FFF')
    $('#' + tab + '-tab div').css('font-weight', 'bold')
    
    $('#event-tab').click(function(){
        window.location = $('#event-tab').attr('url');
    });
	
    $('#supplierview-tab').click(function(){
        window.location = $('#supplierview-tab').attr('url');
    });
    
    $('#template-tab').click(function(){
        window.location = $('#template-tab').attr('url');
    });
    $('#supplier-tab').click(function(){
        window.location = $('#supplier-tab').attr('url');
    });
    $('#item-tab').click(function(){
        window.location = $('#item-tab').attr('url');
    });    
    $('#admin-tab').click(function(){
        window.location = $('#admin-tab').attr('url');
    });    

}

