require 'spec_helper'

describe "Users" do
  describe "GET /compare/[users...]" do
    before do
      [User, Movie].each { |model| model.collection.remove }
      @mislav = User.create username: 'mislav'
      @ivana  = User.create username: 'ivana'
    end

    it "compares two users" do
      get compare_path('ivana+mislav')
      response.status.should be(200)
    end

    it "can't compare one user" do
      get compare_path('ivana')
      response.status.should be(400)
    end

    it "can't compare three users" do
      get compare_path('ivana+mislav+another')
      response.status.should be(400)
    end

    it "handles user not found" do
      get compare_path('ivana+idontexist')
      response.status.should be(404)
    end
  end
end
