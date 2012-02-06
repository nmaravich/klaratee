require 'test_helper'

class EventsSuppliersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:events_suppliers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create events_supplier" do
    assert_difference('EventsSupplier.count') do
      post :create, :events_supplier => { }
    end

    assert_redirected_to events_supplier_path(assigns(:events_supplier))
  end

  test "should show events_supplier" do
    get :show, :id => events_suppliers(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => events_suppliers(:one).to_param
    assert_response :success
  end

  test "should update events_supplier" do
    put :update, :id => events_suppliers(:one).to_param, :events_supplier => { }
    assert_redirected_to events_supplier_path(assigns(:events_supplier))
  end

  test "should destroy events_supplier" do
    assert_difference('EventsSupplier.count', -1) do
      delete :destroy, :id => events_suppliers(:one).to_param
    end

    assert_redirected_to events_suppliers_path
  end
end
