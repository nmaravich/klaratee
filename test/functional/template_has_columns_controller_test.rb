require 'test_helper'

class TemplateHasColumnsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:template_has_columns)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create template_has_column" do
    assert_difference('TemplateHasColumn.count') do
      post :create, :template_has_column => { }
    end

    assert_redirected_to template_has_column_path(assigns(:template_has_column))
  end

  test "should show template_has_column" do
    get :show, :id => template_has_columns(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => template_has_columns(:one).to_param
    assert_response :success
  end

  test "should update template_has_column" do
    put :update, :id => template_has_columns(:one).to_param, :template_has_column => { }
    assert_redirected_to template_has_column_path(assigns(:template_has_column))
  end

  test "should destroy template_has_column" do
    assert_difference('TemplateHasColumn.count', -1) do
      delete :destroy, :id => template_has_columns(:one).to_param
    end

    assert_redirected_to template_has_columns_path
  end
end
