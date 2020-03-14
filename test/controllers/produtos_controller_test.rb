require 'test_helper'

class ProdutosControllerTest < ActionDispatch::IntegrationTest
  test "should get woocommerce_list" do
    get produtos_woocommerce_list_url
    assert_response :success
  end

  test "should get ideal_soft_list" do
    get produtos_ideal_soft_list_url
    assert_response :success
  end

end
