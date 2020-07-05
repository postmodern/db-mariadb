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
	module MariaDB
		module IO
			def self.new(fd, mode)
				Async::IO::Generic.new(::IO.new(fd, mode, autoclose: false))
			end
		end
		
		# This implements the interface between the underyling native interface interface and "standardised" connection interface.
		class Connection < Async::Pool::Resource
			def initialize(**options)
				@native = Native::Connection.connect(**options)
				
				super()
			end
			
			def close
				@native.close
				
				super
			end
			
			def append_string(value, buffer = String.new)
				buffer << "'" << @native.escape(value) << "'"
				
				return buffer
			end
			
			def append_literal(value, buffer = String.new)
				case value
				when Numeric
					buffer << value.to_s
				when TrueClass
					buffer << 'TRUE'
				when FalseClass
					buffer << 'FALSE'
				when nil
					buffer << 'NULL'
				else
					append_string(value, buffer)
				end
				
				return buffer
			end
			
			def append_identifier(value, buffer = String.new)
				buffer << "`" << @native.escape(value) << "`"
				
				return buffer
			end
			
			def id_column(name = 'id', primary_key: true)
				buffer = String.new
				
				append_identifier(name, buffer)
				
				buffer << " BIGINT AUTO_INCREMENT"
				
				if primary_key
					buffer << " PRIMARY KEY"
				end
				
				return buffer
			end
			
			def status
				@native.status
			end
			
			def send_query(statement)
				@native.discard_results
				
				@native.send_query(statement)
			end
			
			def next_result
				@native.next_result
			end
		end
	end
end
