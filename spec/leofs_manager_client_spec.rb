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
    LeoFSManager::VERSION.should eql "0.0.1"
  end

  it "has command list" do
    defined?(LeoFSManager::Commands).should eql "constant"
    LeoFSManager::Commands.all? {|command| command.instance_of? Symbol }.should be_true
  end

  describe ".classify" do
    subject { LeoFSManager.classify(:s3_gen_key) }

    it "returns classified String" do
      should be_a String
      should_not be_empty
      should eql "S3GenKey"
    end
  end

  describe LeoFSManager::RecurStruct do
    subject { LeoFSManager::RecurStruct.new(:a => { :b => :c }) }

    it "is accesible like method call" do
      subject.a.b.should eql :c
    end

    it "is recursively created" do
      subject.class.should eql subject.a.class
    end
  end

  it "raises error when it is passed invalid params" do
    lambda { LeoFSManager.new }.should raise_error
  end

  it "succeeds to execute all commmands" do
    LeoFSManager::Commands.each do |command|
      json = @manager.send(command)
      json[:result].chomp.should eql command.to_s
    end
  end

  it "fails to execute command which doesn't exist" do
    lambda { manager.hogefuga }.should raise_error
  end

  it "accepts args" do
    json = @manager.send(:s3_gen_key, "user_id")
    json[:result].should eql "s3_gen_key user_id\n"
  end
end
