# frozen_string_literal: true

# Copyright, 2020, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'async/pool/resource'
require_relative 'native/connection'

module DB
	module MySQL
		module IO
			def self.new(fd, mode)
				Async::IO::Generic.new(::IO.new(fd, mode, autoclose: false))
			end
		end
		
		# This implements the interface between the underlying 
		class Connection < Async::Pool::Resource
			def initialize(connection_string)
				@native = Native::Connection.connect(
					connection_string, io: IO
				)
				
				super()
			end
			
			def send_query(statement)
				@native.send_query(statement)
			end
			
			def next_result
				@native.next_result
			end
			
			def call(statement)
				@native.send_query(statement)
				
				last_result = nil
				
				while result = @native.next_result
					last_result = result
				end
				
				return last_result
			end
		end
	end
end
