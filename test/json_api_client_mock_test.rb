require 'test_helper'

class JsonApiClientMockTest < MiniTest::Unit::TestCase

  def teardown
    JsonApiClient::Resource.clear_test_results
    super
  end

  def test_get_index
    BarResource.set_test_results([{foo: 'bar', qwer: 'asdf'}])
    results = BarResource.all

    assert_equal(JsonApiClient::ResultSet, results.class)
    assert_equal(1, results.length)

    first = results.first
    assert_equal(BarResource, first.class)
    assert_equal('bar', first.foo)
    assert_equal('asdf', first.qwer)
  end

  def test_get_show
    BarResource.set_test_results({id: 5, foo: 'bar', qwer: 'asdf'})
    results = BarResource.find(5)

    assert_equal(JsonApiClient::ResultSet, results.class)
    assert_equal(1, results.length)

    first = results.first
    assert_equal(BarResource, first.class)
    assert_equal('bar', first.foo)
    assert_equal('asdf', first.qwer)
  end

  def test_patch_update
    BarResource.set_test_results({id: 5, foo: 'bar', qwer: 'asdf'})
    BarResource.set_test_results({id: 5, foo: 'bar', qwer: '123'}, {}, {}, :patch)
    result = BarResource.find(5).first
    result.qwer = '123'

    assert result.save
    assert_equal('123', result.qwer)
  end

  def test_post_create
    BarResource.set_test_results({id: 5, foo: 'bar', qwer: 'asdf'}, {}, {}, :post)
    result = BarResource.create(foo: 'bar', qwer: 'asdf')

    assert result.persisted?
    assert_equal('bar', result.foo)
    assert_equal('asdf', result.qwer)
  end

  def test_get_index_nested
    CocktailResource.set_test_results([{bar_id: 2, foo: 'bar'}])
    results = CocktailResource.where(bar_id: 2).all

    assert_equal(JsonApiClient::ResultSet, results.class)
    assert_equal(1, results.length)

    first = results.first
    assert_equal(CocktailResource, first.class)
    assert_equal('bar', first.foo)
  end

  def test_get_show_nested
    CocktailResource.set_test_results({id: 5, bar_id: 2, foo: 'bar'})
    results = CocktailResource.where(bar_id: 2).find(5)

    assert_equal(JsonApiClient::ResultSet, results.class)
    assert_equal(1, results.length)

    first = results.first
    assert_equal(CocktailResource, first.class)
    assert_equal('bar', first.foo)
  end

  def test_conditionless_mocking
    BarResource.set_test_results([{foo: 'bar', qwer: 'asdf'}])
    results = BarResource.all

    assert_equal(JsonApiClient::ResultSet, results.class)
    assert_equal(1, results.length)

    first = results.first
    assert_equal(BarResource, first.class)
    assert_equal('bar', first.foo)
    assert_equal('asdf', first.qwer)

    conditioned_results = BarResource.where(something: 'else').all
    assert_equal(JsonApiClient::ResultSet, results.class)
    assert_equal(1, conditioned_results.length)

    first = conditioned_results.first
    assert_equal(BarResource, first.class)
    assert_equal('bar', first.foo)
    assert_equal('asdf', first.qwer)
  end

  def test_missing_mock
    assert_raises(JsonApiClientMock::MissingMock) do
      BarResource.all
    end
  end

  def test_conditional_mocking
    BarResource.set_test_results([{foo: 'bar', qwer: 'asdf'}], {filter: {foo: 'bar'}})
    assert_raises(JsonApiClientMock::MissingMock) do
      BarResource.all
    end

    results = BarResource.where(foo: 'bar').all
    assert_equal(1, results.length)

    first = results.first
    assert_equal(BarResource, first.class)
    assert_equal('bar', first.foo)
    assert_equal('asdf', first.qwer)
  end

  def test_meta_response
    BarResource.set_test_results([{foo: 'bar', qwer: 'asdf'}], {filter: {foo: 'bar'}}, {meta_attr: 1000})
    results = BarResource.where(foo: 'bar').all

    assert_equal(1000, results.meta[:meta_attr])
  end

  def test_by_conditional_request_path_mocking
    BarResource.set_test_results({id: 10, foo: 'bar', qwer: 'asdf'})
    assert_raises(JsonApiClientMock::MissingMock) do
      BarResource.all
    end

    results = BarResource.find(10)
    assert_equal(1, results.length)

    first = results.first
    assert_equal(BarResource, first.class)
    assert_equal('bar', first.foo)
    assert_equal('asdf', first.qwer)
  end

  def test_conditional_mocking_param_order
    BarResource.set_test_results([{foo: 'bar', qwer: 'asdf'}], {filter: {foo: 'bar', qwer: 'asdf'}})

    results = BarResource.where(foo: 'bar', qwer: 'asdf').all
    assert_equal(1, results.length)

    results = BarResource.where(qwer: 'asdf', foo: 'bar').all
    assert_equal(1, results.length)
  end

  def test_mocks_are_stored_by_class
    BarResource.set_test_results([{foo: 'bar', qwer: 'asdf'}])
    assert_raises(JsonApiClientMock::MissingMock) do
      FooResource.all
    end
  end

  def test_inherited_mocking
    BarResource.set_test_results([{foo: 'bar', qwer: 'asdf'}])
    assert_raises(JsonApiClientMock::MissingMock) do
      BarExtendedResource.all
    end
  end

  def test_allow_net_connect
    BarResource.allow_net_connect!

    BarResource.connection

    # base still has mock connection
    assert_equal JsonApiClientMock::MockConnection,
      JsonApiClient::Resource.connection_class

    # other connections still have mock connection
    assert_equal JsonApiClientMock::MockConnection,
      FooResource.connection_class

    # bar has real connection
    assert_equal JsonApiClient::Connection,
      BarResource.connection_class

    # actual connection is not a mock
    assert_equal JsonApiClient::Connection,
      BarResource.connection_object.class

    BarResource.disable_net_connect!

    BarResource.connection

    # bar has mock connection again
    assert_equal JsonApiClientMock::MockConnection,
      BarResource.connection_class

    # actual connection is a mock again
    assert_equal JsonApiClientMock::MockConnection,
      BarResource.connection_object.class
  end
end
