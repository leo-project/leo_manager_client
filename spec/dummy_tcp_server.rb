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

module Dummy
  module Response
    Login = {
      :user => {
        :id => "foo",
        :role_id => 0,
        :access_key_id => "855d2f9bf21f51b4fd38",
        :secret_key => "ea6d9540d6385f32d674c925929748e00e0e961a",
        :created_at => "2012-11-29 17:18:39 +0900"
      }
    }.to_json

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
          :timestamp => "2012-12-07 16:51:08 +0900",
          :delete => 0,
          :num_of_chunks => 0
        }
      ]
    }.to_json

    StorageStat = {
      :active_num_of_objects => 0,
      :total_num_of_objects => 0,
      :active_size_of_objects => 0,
      :total_size_of_objects => 0,
      :ratio_of_active_size => 0,
      :last_compaction_start => "2013-03-13 09:11:04 +0900",
      :last_compaction_end => "2013-03-13 09:11:04 +0900"
    }.to_json

    GetEndpoints = {:endpoints => [{:endpoint => "s3.amazonaws.com", :created_at=>"2012-09-21 15:08:11 +0900"},
                                   {:endpoint => "localhost",        :created_at=>"2012-09-21 15:08:11 +0900"},
                                   {:endpoint => "foo",              :created_at=>"2012-09-21 18:51:08 +0900"},
                                   {:endpoint => "leofs.org",        :created_at=>"2012-09-21 15:08:11 +0900"}
                                  ]}.to_json
    GetBuckets = {:buckets => [{:bucket => "test",
                                :owner => "test",
                                :created_at => "2012-09-24 15:38:49 +0900"
                               }]}.to_json

    GetUsers = {:users => [{:access_key_id => "05236",
                             :user_id => "_test_leofs_",
                             :role_id => 1,
                             :created_at => "2012-11-20 15:13:20 +0900"}]}.to_json

    CreateUser = {:access_key_id => "xxxxxxxxxxxxxxxxxxxx",
                  :secret_access_key => "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"}.to_json
  end

  Argument = "arg" # passed to command which requires some arguments.

  # dummy Manager
  class Manager
    def initialize
      t = Thread.new do
        TCPServer.open(Host, Port) do |server|
          loop do
            begin
              socket = server.accept
              while line = socket.readline.split.first
                response = process_line(line)
                socket.puts(response)
              end
            rescue EOFError
            end
          end
        end
      end
      nil until t.stop? # wait server start
    end

    def process_line(line)
      line.rstrip!
      begin
        case line
        when "login"
          Response::Login
        when "status"
          Response::Status
        when "get-buckets"
          Response::GetBuckets
        when "whereis"
          Response::Whereis
        when "get-endpoints"
          Response::GetEndpoints
        when "get-buckets"
          Response::GetBuckets
        when "get-users"
          Response::GetUsers
        when "create-user"
          Response::CreateUser
        when /^du/
          Response::StorageStat
        else
          { :result => line }.to_json
        end
      rescue => ex
        { :error => ex.message }.to_json
      end
    end
  end
end
