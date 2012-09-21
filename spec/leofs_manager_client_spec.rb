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

# dummy TCP server
Thread.new do
  TCPServer.open(Host, Port) do |server|
    loop do
      socket = server.accept
      while line = socket.gets
        json = { :result => line }.to_json
        socket.puts(json)
      end
    end
  end
end

describe LeoFSManager do
  before(:all) do
    @manager = LeoFSManager.new("#{Host}:#{Port}")
  end

  it "has version" do
    defined?(LeoFSManager::VERSION).should eql "constant"
    LeoFSManager::VERSION.should eql "0.2.0"
  end

  it "raises error when it is passed invalid params" do
    lambda { LeoFSManager.new }.should raise_error
  end

  it "returns status" do
    p @manager.status
  end

  it "fails to execute command which doesn't exist" do
    lambda { manager.hogefuga }.should raise_error
  end

  it "accepts args" do
    json = @manager.send(:s3_gen_key, "user_id")
    json[:result].should eql "s3_gen_key user_id\n"
  end
end
