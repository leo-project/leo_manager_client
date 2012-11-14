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
          :delete => 0,
          :num_of_chunks => 0
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

  Argument = "arg" # passed to command which requires some arguments.

  # dummy Manager
  class Manager
    Thread.new do
      TCPServer.open(Host, Port) do |server|
        loop do
          begin
            socket = server.accept
            while line = socket.readline.split.first
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
          rescue EOFError
          end
        end
      end
    end
  end
end
