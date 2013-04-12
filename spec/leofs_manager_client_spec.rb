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
  :purge => 1,
  :set_endpoint => 1,
  :del_endpoint => 1,
  :add_bucket => 2,
  :delete_bucket => 2
}

include LeoFSManager

describe LeoFSManager do
  describe StorageStat do
    shared_examples_for StorageStat do
      its(:active_num_of_objects) { should == 0 }
      its(:total_num_of_objects) { should == 0 }
      its(:active_size_of_objects) { should == 0 }
      its(:total_size_of_objects) { should == 0 }
    end

    context "there is no last compaction" do
      subject do
        StorageStat.new(:active_num_of_objects => 0,
                        :total_num_of_objects => 0,
                        :active_size_of_objects => 0,
                        :total_size_of_objects => 0,
                        :ratio_of_active_size => "0.0%",
                        :last_compaction_start => "____-__-__ __:__:__",
                        :last_compaction_end => "____-__-__ __:__:__"
                        )
      end

      it_behaves_like StorageStat

      its(:last_compaction_start) { should be_nil }
      its(:last_compaction_end) { should be_nil }
    end

    context "there is last compaction" do
      let(:time_str) { Time.now.to_s }

      subject do
        StorageStat.new(
          :active_num_of_objects => 0,
          :total_num_of_objects => 0,
          :active_size_of_objects => 0,
          :total_size_of_objects => 0,
          :last_compaction_start => time_str,
          :last_compaction_end => time_str
        )
      end

      it_behaves_like StorageStat

      its(:last_compaction_start) { subject.to_s == time_str }
      its(:last_compaction_end) { subject.to_s == time_str }
    end
  end

  describe Status do
    describe Status::System do
      let(:ring_hash) { "1679896365" }

      subject do
        Status::System.new({
          :version   => "0.14.0",
          :n         => "2",
          :r         => "1",
          :w         => "1",
          :d         => "1",
          :ring_size => "128",
          :ring_hash_cur  => ring_hash,
          :ring_hash_prev => ring_hash
        })
      end

      [:n, :r, :w, :d, :ring_size].each do |property|
        its(property) { should be_a Integer }
      end

      [:ring_cur, :ring_prev].each do |property|
        its(property) { should be_a String }
        its(property) { should == Integer(ring_hash).to_s(16) }
      end
    end

    describe Status::NodeStat do
      config = {
        :version    => "0.14.0-RC2",
        :log_dir    => "./log",
        :ring_cur   => "64212f2d",
        :ring_prev  => "64212f2d",
        :vm_version => "5.9.3.1",
        :total_mem_usage  => 29281552,
        :system_mem_usage => 11874433,
        :procs_mem_usage  => 17411895,
        :ets_mem_usage    => 1022392,
        :num_of_procs     => 325,
        :limit_of_procs   => 1048576,
        :kernel_poll      => "true",
        :thread_pool_size => 32,
        :replication_msgs => 0,
        :sync_vnode_msgs  => 0,
        :rebalance_msgs   => 0
      }

      subject do
        Status::NodeStat.new(config)
      end

      its(:kernel_poll) { should == (config[:kernel_poll] == "true") }
      _config = config.reject {|key| key == :kernel_poll }
      _config.each {|key, value| its(key) { should == value } }
    end
  end

  describe Client do
    before(:all) do
      Dummy::Manager.new
      @manager = Client.new("#{Host}:#{Port}")
    end
    subject { @manager }

    it "raises error when it is passed invalid params" do
      lambda { Client.new }.should raise_error
    end

    describe "#login" do
      it "returns LoginInfo" do
        subject.login("user_id", "pass").should be_a LoginInfo
      end
    end

    describe "#status" do
      its(:status) { should be_a Status }
      its("status.system_info") { should be_a Status::System }
      its("status.node_list") do
        should be_a Array
        should be_all {|node| node.is_a?(Status::Node) }
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

    describe "#create_user" do
      it "returns Credential" do
        subject.create_user("user_id", "password").should be_a Credential
      end

      it "goes with only user_id" do
        subject.create_user("user_id").should be_a Credential
      end
    end

    describe "#update_user_role" do
      it "returns nil" do
        subject.update_user_role("user_id", "admin").should be_nil
      end
    end

    describe "#update_user_password" do
      it "returns nil" do
        subject.update_user_password("user_id", "new_password").should be_nil
      end
    end

    describe "#delete_user" do
      it "returns nil" do
        subject.delete_user("user_id").should be_nil
      end
    end

    its(:get_users) do
      should be_a Array
      should be_all do |account|
        account.is_a?(User)
      end
    end

    its(:get_endpoints) do
      should be_a Array
      should be_all do |endpoint|
        endpoint.is_a?(Endpoint)
      end
    end

    its(:get_buckets) do
      should be_a Array
      should be_all do |bucket|
        bucket.is_a?(Bucket)
      end
    end

    describe "#recover_file" do
      it do
        subject.recover_file("path").should be_nil
      end
    end

    describe "#recover_node" do
      it do
        subject.recover_node("node").should be_nil
      end
    end

    describe "#recover_ring" do
      it do
        subject.recover_ring("node").should be_nil
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
