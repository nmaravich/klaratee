require 'test_helper'

class DataTemplatesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:data_templates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create data_template" do
    assert_difference('DataTemplate.count') do
      post :create, :data_template => { }
    end

    assert_redirected_to data_template_path(assigns(:data_template))
  end

  test "should show data_template" do
    get :show, :id => data_templates(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => data_templates(:one).to_param
    assert_response :success
  end

  test "should update data_template" do
    put :update, :id => data_templates(:one).to_param, :data_template => { }
    assert_redirected_to data_template_path(assigns(:data_template))
  end

  test "should destroy data_template" do
    assert_difference('DataTemplate.count', -1) do
      delete :destroy, :id => data_templates(:one).to_param
    end

    assert_redirected_to data_templates_path
  end
end
