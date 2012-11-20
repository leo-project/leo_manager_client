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

require "json"
require_relative "dummy_tcp_server"
require_relative "../lib/leofs_manager_client"

Host = "localhost"
Port = 50000

$DEBUG = false

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
  describe Client do
    before(:all) do
      Dummy::Manager.new
      @manager = Client.new("#{Host}:#{Port}")
    end
    subject { @manager }

    it "raises error when it is passed invalid params" do
      lambda { Client.new }.should raise_error
    end

    describe "#status" do
      its(:status) { should be_a Status }
      its("status.system_info") { should be_a Status::System }

      its("status.node_list") do
        should be_a Array
        subject.each do |node|
          node.should be_a Status::Node
        end
      end
    end

    describe "#whereis" do
      it "returns Array of WhereInfo" do
        result = subject.whereis("path")
        result.should be_a Array
        result.each do |where_info|
          where_info.should be_a AssignedFile
          where_info.num_of_chunks.should be_a Integer
        end
      end    
    end

    describe "#du" do
      it "returns DiskUsage" do
        subject.du("node").should be_a StorageStat
      end
    end

    describe "#s3_create_key" do
      it "returns Credential" do
        subject.s3_create_key("user_id").should be_a Credential
      end 
    end

    its(:s3_get_keys) do
      should be_a Array
      subject.each do |account|
        account.should be_a User
      end
    end

    its(:s3_get_endpoints) do
      should be_a Array
      subject.each do |endpoint|
        endpoint.should be_a Endpoint
      end
    end

    its(:s3_get_buckets) do
      should be_a Array
      subject.each do |buckets|
        buckets.should be_a Bucket
      end
    end

    NoResultAPIs.each do |api, num_of_args|
      describe "##{api}" do
        it "returns nil" do
          subject.send(api, *(["argument"] * num_of_args)).should be_nil
        end
      end
    end

    describe "#disconnect!" do
      it "returns nil" do
        subject.disconnect!.should be_nil
      end

      it "accepts no more requests" do
        lambda {
          subject.status
        }.should raise_error
      end
    end
  end
end
