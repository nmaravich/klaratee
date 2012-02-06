require 'test_helper'

class TemplateSuppliersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:template_suppliers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create template_supplier" do
    assert_difference('TemplateSupplier.count') do
      post :create, :template_supplier => { }
    end

    assert_redirected_to template_supplier_path(assigns(:template_supplier))
  end

  test "should show template_supplier" do
    get :show, :id => template_suppliers(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => template_suppliers(:one).to_param
    assert_response :success
  end

  test "should update template_supplier" do
    put :update, :id => template_suppliers(:one).to_param, :template_supplier => { }
    assert_redirected_to template_supplier_path(assigns(:template_supplier))
  end

  test "should destroy template_supplier" do
    assert_difference('TemplateSupplier.count', -1) do
      delete :destroy, :id => template_suppliers(:one).to_param
    end

    assert_redirected_to template_suppliers_path
  end
end
