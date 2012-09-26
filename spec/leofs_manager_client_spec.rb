# ======================================================================
# 
#  LeoFS Manager Client
# 
#  Copyright (c) 2012 Rakuten, Inc.
# 
#  This file is provided to you under the Apache License,
#  Version 2.0 (the "License"); you may not use this file
#  except in compliance with the License.  You may obtain
#  a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
#  specific language governing permissions and limitations
#  under the License.
# 
# ======================================================================

require "socket"
require "json"
require_relative "../lib/leofs_manager_client"

Host = "localhost"
Port = 50000

$DEBUG = false
Thread.abort_on_exception = true

module Dummy
  module Response
    Status = {
      :system_info => {
        :version => "0.10.1",
        :n => "1",
        :r => "1",
        :w => "1",
        :d => "1",
        :ring_size => "128",
        :ring_hash_cur => "2688134336",
        :ring_hash_prev => "2688134336"},
        :node_list => [
          {
            :type => "S",
            :node => "storage_0@127.0.0.1",
            :state => "running",
            :ring_cur => "a039acc0",
            :ring_prev => "a039acc0",
            :when => "2012-09-21 15:08:22 +0900"
          }, {
            :type => "G",
            :node => "gateway_0@127.0.0.1",
            :state => "running",
            :ring_cur => "a039acc0",
            :ring_prev => "a039acc0",
            :when => "2012-09-21 15:08:25 +0900"
          }
        ]
    }.to_json

    Whereis = {
      :assigned_info => [
        { 
          :node => "storage_0@127.0.0.1",
          :vnode_id => "",
          :size => "",
          :clock => "",
          :checksum => "",
          :timestamp => "",
          :delete => 0
        }
      ]
    }.to_json

    S3GetEndpoints = {
      :endpoints => [
        {:endpoint => "s3.amazonaws.com", :created_at=>"2012-09-21 15:08:11 +0900"},
        {:endpoint => "localhost", :created_at=>"2012-09-21 15:08:11 +0900"},
        {:endpoint => "foo", :created_at=>"2012-09-21 18:51:08 +0900"},
        {:endpoint => "leofs.org", :created_at=>"2012-09-21 15:08:11 +0900"}
      ]
    }.to_json

    S3GetBuckets = {
      :buckets => [
        {
          :bucket => "test",
          :owner => "test",
          :created_at => "2012-09-24 15:38:49 +0900"
        }
      ]
    }.to_json
  end

  Argument = "hoge" # passed to command which requires some arguments.

  # dummy Manager
  class Manager
    Thread.new do
      TCPServer.open(Host, Port) do |server|
        loop do
          socket = server.accept
          while line = socket.gets.split.first
            line.rstrip!
            begin
              case line
              when "status"
                result = Response::Status
              when "s3-get-buckets"
                result = Response::S3GetBuckets
              when "whereis"
                result = Response::Whereis
              when "s3-get-endpoints"
                result = Response::S3GetEndpoints
              when "s3-get-buckets"
                result = Response::S3GetBuckets
              else
                result = { :result => line }.to_json
              end
            rescue => ex
              result = { :error => ex.message }.to_json
            ensure
              socket.puts(result)
            end
          end
        end
      end
    end
  end
end

# key: api_name, value: num of args
NoResultAPIs = {
  :start => 0, 
  :detach => 1, 
  :rebalance => 0, 
  :compact => 1, 
  :purge => 1,
  :s3_set_endpoint => 1, 
  :s3_del_endpoint => 1, 
  :s3_add_bucket => 2
}

include LeoFSManager

describe LeoFSManager do
  before(:all) do
    Dummy::Manager.new
    @manager = Client.new("#{Host}:#{Port}")
  end

  it "raises error when it is passed invalid params" do
    lambda { Client.new }.should raise_error
  end

  describe "#status" do
    it "returns Status" do
      @manager.status.should be_a Status
    end

    it "returns SystemInfo" do
      @manager.status.system_info.should be_a Status::System
    end

    it "returns node list" do
      node_list = @manager.status.node_list
      node_list.should be_a Array
      node_list.each do |node|
        node.should be_a Status::Node
      end
    end
  end

  describe "#whereis" do
    it "returns Array of WhereInfo" do
      result = @manager.whereis("path")
      result.should be_a Array
      result.each do |where_info|
        where_info.should be_a AssignedFile
      end
    end    
  end

  describe "#du" do
    it "returns DiskUsage" do
      @manager.du("node").should be_a StorageStat
    end
  end

  describe "#s3_gen_key" do
    it "returns Credential" do
      @manager.s3_gen_key("user_id").should be_a Credential
    end 
  end

  describe "#s3_get_endpoints" do
    it "returns Arrany of Endpoint" do
      result = @manager.s3_get_endpoints
      result.should be_a Array
      result.each do |endpoint|
        endpoint.should be_a Endpoint
      end
    end
  end

  describe "#s3_get_buckets" do
    it "returns Array of Bucket" do
      result = @manager.s3_get_buckets
      result.should be_a Array
      result.each do |buckets|
        buckets.should be_a Bucket
      end
    end
  end

  NoResultAPIs.each do |api, num_of_args|
    describe "##{api}" do
      it "returns nil" do
        @manager.send(api, *(["argument"] * num_of_args)).should be_nil
      end
    end
  end
end
