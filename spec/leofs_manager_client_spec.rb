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
  Status = {
    :system_info =>
    { :version=>"0.10.1",
      :n=>"1",
      :r=>"1",
      :w=>"1",
      :d=>"1",
      :ring_size=>"128",
      :ring_hash_cur=>"2688134336",
      :ring_hash_prev=>"2688134336"},
     :node_list=>
      [{:type=>"S",
        :node=>"storage_0@127.0.0.1",
        :state=>"running",
        :ring_cur=>"a039acc0",
        :ring_prev=>"a039acc0",
        :when=>"2012-09-21 15:08:22 +0900"},
       {:type=>"G",
        :node=>"gateway_0@127.0.0.1",
        :state=>"running",
        :ring_cur=>"a039acc0",
        :ring_prev=>"a039acc0",
        :when=>"2012-09-21 15:08:25 +0900"}]
  }.to_json

  # dummy Manager
  class Manager
    Thread.new do
      TCPServer.open(Host, Port) do |server|
        loop do
          socket = server.accept
          while line = socket.gets
            line.chomp!
            case line
            when "status"
              result = Status
            else
              result = { :result => line }.to_json
            end
            socket.puts(result)
          end
        end
      end
    end
  end
end

describe LeoFSManager do
  before(:all) do
    Dummy::Manager.new
    @manager = LeoFSManager::Client.new("#{Host}:#{Port}")
  end

  it "has version" do
    defined?(LeoFSManager::VERSION).should eql "constant"
    LeoFSManager::VERSION.should eql "0.2.0"
  end

  it "raises error when it is passed invalid params" do
    lambda { LeoFSManager.new }.should raise_error
  end

  describe "#status" do
    it "returns Hash" do
      @manager.status.should be_a Hash
    end

    it "returns SystemInfo" do
      @manager.status[:system_info].should be_a LeoFSManager::SystemInfo
    end
  end
end
