require 'test_helper'

class DataTemplateColumnsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:data_template_columns)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create data_template_column" do
    assert_difference('DataTemplateColumn.count') do
      post :create, :data_template_column => { }
    end

    assert_redirected_to data_template_column_path(assigns(:data_template_column))
  end

  test "should show data_template_column" do
    get :show, :id => data_template_columns(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => data_template_columns(:one).to_param
    assert_response :success
  end

  test "should update data_template_column" do
    put :update, :id => data_template_columns(:one).to_param, :data_template_column => { }
    assert_redirected_to data_template_column_path(assigns(:data_template_column))
  end

  test "should destroy data_template_column" do
    assert_difference('DataTemplateColumn.count', -1) do
      delete :destroy, :id => data_template_columns(:one).to_param
    end

    assert_redirected_to data_template_columns_path
  end
end
