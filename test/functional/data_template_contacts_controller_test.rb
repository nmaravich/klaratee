require 'test_helper'

class DataTemplateContactsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:data_template_contacts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create data_template_contact" do
    assert_difference('DataTemplateContact.count') do
      post :create, :data_template_contact => { }
    end

    assert_redirected_to data_template_contact_path(assigns(:data_template_contact))
  end

  test "should show data_template_contact" do
    get :show, :id => data_template_contacts(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => data_template_contacts(:one).to_param
    assert_response :success
  end

  test "should update data_template_contact" do
    put :update, :id => data_template_contacts(:one).to_param, :data_template_contact => { }
    assert_redirected_to data_template_contact_path(assigns(:data_template_contact))
  end

  test "should destroy data_template_contact" do
    assert_difference('DataTemplateContact.count', -1) do
      delete :destroy, :id => data_template_contacts(:one).to_param
    end

    assert_redirected_to data_template_contacts_path
  end
end
